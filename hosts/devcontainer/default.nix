{ pkgs, dotfilesInput, ... }:

let
  # This builds an environment that contains symlinks to all our packages.
  nixProfile = pkgs.buildEnv {
    name = "nix-profile";
    paths = myPackages;
  };

  # This script will be placed in /etc/profile.d/ and sourced by new shells.
  envSetupScript = pkgs.runCommand "env-setup-script" { } ''
    mkdir -p $out/etc/profile.d
    # This line sets the PATH to include our Nix profile, followed by a standard default.
    # It ensures that Nix packages are found first.
    echo 'export PATH="${nixProfile}/bin:/bin:/usr/bin:/sbin:/usr/sbin"' > $out/etc/profile.d/nix-env.sh
  '';

  devSetup = pkgs.runCommand "dev-setup" { } ''
    mkdir -p $out/etc
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "arthur:x:1000:1000:Arthur:/home/arthur:/bin/bash" >> $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
    echo "arthur:x:1000:" >> $out/etc/group
    echo "hosts: files dns" > $out/etc/nsswitch.conf
  '';

  dotfilesLayer = pkgs.runCommand "dotfiles-layer" { } ''
    mkdir -p $out/opt
    cp -r ${dotfilesInput} $out/opt/dotfiles
  '';

  devContainerSetupScript = pkgs.writeScriptBin "setup_devcontainer.sh" ''
    #!${pkgs.bash}/bin/bash
    set -e
    DOTFILES_DIR="/home/arthur/.dotfiles"
    BACKUP_SOURCE="/opt/dotfiles"
    MARKER_FILE="/home/arthur/.dotfiles_setup_complete"

    # --- 1. Clone/Restore Dotfiles (Idempotent: Only if dir doesn't exist) ---
    if [ ! -d "$DOTFILES_DIR" ]; then
      echo "--- First run detected: Installing Dotfiles ---"
      if git clone https://github.com/ArthurDelannoyazerty/dotfiles.git "$DOTFILES_DIR"; then
        echo "Git clone successful."
      else
        echo "Git clone failed, using baked-in copy..."
        cp -rL "$BACKUP_SOURCE" "$DOTFILES_DIR"
        chmod -R +w "$DOTFILES_DIR"
      fi
    fi
    
    # --- 2. Run Setup Script (Idempotent: Only if marker file doesn't exist) ---
    if [ ! -f "$MARKER_FILE" ]; then
      if [ -f "$DOTFILES_DIR/setup.sh" ]; then
        echo "Running setup.sh..."
        # Run setup.sh. If it fails, script exits (set -e) and marker is NOT created.
        sh "$DOTFILES_DIR/setup.sh"
        echo "Setup complete."
      fi
      # Create marker so we don't run this next time
      touch "$MARKER_FILE"
    else
      echo "Dotfiles setup already performed. Skipping."
    fi

    # ------------------------------ VSCODE SETUP ------------------------------ 

    EXTENSION_FILE="$DOTFILES_DIR/codium/extensions.txt"
    
    echo "--- VS Code Extension Installer ---"
    
    # Check if we are actually inside VS Code
    if ! command -v code &> /dev/null; then
        echo "Error: 'code' command not found."
        echo "You must run this script INSIDE the VS Code Integrated Terminal."
        exit 1
    fi

    if [ ! -f "$EXTENSION_FILE" ]; then
        echo "Error: Extension list not found at $EXTENSION_FILE"
        exit 1
    fi

    # Loop through the file and install
    echo "Reading extensions from $EXTENSION_FILE..."
    while IFS= read -r ext || [ -n "$ext" ]; do
        # Skip empty lines or comments
        [[ $ext =~ ^# ]] && continue
        [[ -z $ext ]] && continue
        
        echo "Installing $ext..."
        code --install-extension "$ext" --force
    done < "$EXTENSION_FILE"
    
    echo "--- All extensions installed! Reload window to apply. ---"

    # --- 3. Execute Command (if arguments provided) ---
    # This allows the script to still be used as a Docker Entrypoint
    if [ "$#" -gt 0 ]; then
      exec "$@"
    fi
  '';

  atuinConfig = pkgs.writeTextDir "etc/atuin/config.toml" ''
    ## Server config ##
    auto_sync = false
    update_check = false
    sync_address = ""

    ## UI Settings ##
    style = "auto"
    inline_height = 16
    show_preview = true
    
    ## Behavior ##
    enter_accept = true
  '';

in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-devcontainer";
  tag = "latest";

  contents = with pkgs; [
    devSetup
    dotfilesLayer
    devContainerSetupScript
    atuinConfig
    envSetupScript
    
    # --- Base Utils ---
    bashInteractive
    coreutils
    git
    cacert
    curl
    wget
    iana-etc
    zip
    unzip
    openssh
    jq
    pkg-config
    nix-tree
    nil
    gnutar
    gzip
    procps 
    gnugrep
    gnused
    findutils
    gawk
    which
    util-linux
    glibc
    findutils 
    binutils
    # glibc.bin
    stdenv.cc.cc.lib
    dotnet-sdk
    
    # --- Terminal Tools ---
    atuin
    btop
    tree
    nvitop
    starship
    htop
    killall
    duf
    bat
    eza
    fzf
    tldr
    
    # --- Dev Tools ---
    vim
    python3
    nodejs
    gnumake
    gcc
    ripgrep
    fd
    nix
    uv
    docker
  ];

  # You can keep your fakeRootCommands for /usr/bin/env compatibility,
  # but we rely less on the library symlinks now.
  fakeRootCommands = ''
    mkdir -p ./home/arthur
    mkdir -p ./tmp
    mkdir -p ./usr/bin

    # --- 1. CLEANUP ---
    # Remove existing library dirs and any ldconfig that might have snuck in
    rm -rf ./lib ./lib64 ./usr/lib64
    rm -f ./bin/ldconfig ./sbin/ldconfig ./usr/sbin/ldconfig

    # --- 2. FHS DIRECTORY STRUCTURE ---
    mkdir -p ./usr/lib ./usr/bin ./sbin ./usr/sbin ./bin ./etc
    
    ln -sf usr/lib lib
    ln -sf usr/lib lib64
    ln -sf lib usr/lib64

    # --- 3. CONFIGURE LDCONFIG (THE FIX) ---
    
    # A. Create the config file telling ldconfig to look in /usr/lib
    echo "/usr/lib" > ./etc/ld.so.conf
    
    # B. Generate the cache NOW (during build)
    # This creates a valid ./etc/ld.so.cache that VS Code can read later
    ${pkgs.glibc.bin}/bin/ldconfig -r . -f /etc/ld.so.conf -C /etc/ld.so.cache || echo "Cache gen warning"

    # C. Create the Wrapper Script
    # VS Code calls 'ldconfig'. We intercept it and force it to use our 
    # valid cache file instead of the read-only Nix store path.
    cat <<EOF > ./bin/ldconfig
#!/bin/sh
exec ${pkgs.glibc.bin}/bin/ldconfig -C /etc/ld.so.cache "\$@"
EOF
    chmod +x ./bin/ldconfig
    
    # D. Symlink the wrapper to sbin (where VS Code looks)
    ln -sf ../bin/ldconfig ./sbin/ldconfig
    ln -sf ../bin/ldconfig ./usr/sbin/ldconfig

    # --- 4. POPULATE LIBRARIES ---
    
    # VS Code Scripts compatibility
    ln -sf ${pkgs.coreutils}/bin/env ./usr/bin/env

    # Dynamic Loader
    ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ./usr/lib/ld-linux-x86-64.so.2

    # Standard Libraries (Libstdc++, Glibc, GCC)
    find ${pkgs.stdenv.cc.cc.lib} -name "libstdc++.so.6*" -exec ln -sf {} ./usr/lib/ \;
    find ${pkgs.glibc}/lib -name "*.so*" -exec ln -sf {} ./usr/lib/ \;
    find ${pkgs.stdenv.cc.cc.lib} -name "libgcc_s.so.1" -exec ln -sf {} ./usr/lib/ \;

    # ----------------------------------------------

    # Permission setup
    chown -R 1000:1000 ./home/arthur
    chown -R 1000:1000 ./tmp
    chmod 755 ./home/arthur
    chmod 1777 ./tmp
  '';

  config = {
    User = "arthur";
    WorkingDir = "/home/arthur";
    Cmd = [ "/bin/bash" ];
    
    Env = [
      "USER=arthur"
      "HOME=/home/arthur"
      "HISTFILE=/home/arthur/.bash_history"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PATH=/bin:/usr/bin:/usr/local/bin"
      "LANG=C.UTF-8"
      "LC_ALL=C.UTF-8"
      "ATUIN_CONFIG_DIR=/etc/atuin" 
      "LD_LIBRARY_PATH=/usr/lib"
    ];
  };
}