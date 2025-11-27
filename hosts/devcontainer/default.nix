{ pkgs, dotfilesInput, ... }:

let
  dotfilesLayer = pkgs.runCommand "dotfiles-layer" { } ''
    mkdir -p $out/opt
    cp -r ${dotfilesInput} $out/opt/dotfiles
  '';

  entrypointScript = pkgs.writeScriptBin "entrypoint.sh" ''
    #!${pkgs.bash}/bin/bash
    set -e
    DOTFILES_DIR="/home/arthur/.dotfiles"
    BACKUP_SOURCE="/opt/dotfiles"

    if [ ! -d "$DOTFILES_DIR" ]; then
      echo "--- First run detected: Installing Dotfiles ---"
      if git clone https://github.com/ArthurDelannoyazerty/dotfiles.git "$DOTFILES_DIR"; then
        echo "Git clone successful."
      else
        echo "Git clone failed, using baked-in copy..."
        cp -rL "$BACKUP_SOURCE" "$DOTFILES_DIR"
        chmod -R +w "$DOTFILES_DIR"
      fi
      
      if [ -f "$DOTFILES_DIR/setup.sh" ]; then
        echo "Running setup.sh..."
        sh "$DOTFILES_DIR/setup.sh"
      fi
    fi
    exec "$@"
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

  devSetup = pkgs.runCommand "dev-setup" { } ''
    mkdir -p $out/etc
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "arthur:x:1000:1000:Arthur:/home/arthur:/bin/bash" >> $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
    echo "arthur:x:1000:" >> $out/etc/group
    echo "hosts: files dns" > $out/etc/nsswitch.conf
  '';

in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-devcontainer";
  tag = "latest";

  contents = with pkgs; [
    devSetup
    dotfilesLayer
    entrypointScript
    atuinConfig
    
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
    Entrypoint = [ "/bin/entrypoint.sh" ];
    Cmd = [ "/bin/bash" ];
    
    Env = [
      "USER=arthur"
      "HOME=/home/arthur"
      "PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin" # Added sbin for ldconfig
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