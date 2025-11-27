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
    glibc.bin
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
    rm -rf ./lib ./lib64 ./usr/lib64

    # --- 2. FHS DIRECTORY STRUCTURE ---
    mkdir -p ./usr/lib ./usr/bin ./sbin
    ln -sf usr/lib lib
    ln -sf usr/lib lib64
    ln -sf lib usr/lib64

    # --- 3. TOOLS COMPATIBILITY ---
    ln -sf ${pkgs.coreutils}/bin/env ./usr/bin/env
    
    # Link ldconfig to where scripts expect it
    ln -sf ${pkgs.glibc.bin}/bin/ldconfig ./sbin/ldconfig
    ln -sf ${pkgs.glibc.bin}/bin/ldconfig ./usr/sbin/ldconfig

    # --- 4. POPULATE LIBRARIES ---
    # Dynamic Loader
    ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ./usr/lib/ld-linux-x86-64.so.2

    # Libstdc++ (C++)
    # We follow symlinks (-L) to ensure we get the actual .so file if needed
    find ${pkgs.stdenv.cc.cc.lib} -name "libstdc++.so.6*" -exec ln -sf {} ./usr/lib/ \;

    # Glibc (C)
    find ${pkgs.glibc}/lib -name "*.so*" -exec ln -sf {} ./usr/lib/ \;
    
    # GCC Libs
    find ${pkgs.stdenv.cc.cc.lib} -name "libgcc_s.so.1" -exec ln -sf {} ./usr/lib/ \;

    # ----------------------------------------------
    
    # Create an ld.so.cache so ldconfig doesn't complain (optional but good)
    # We try to run ldconfig to generate the cache for the libs we just linked
    # We need to use the fake root path
    ${pkgs.glibc.bin}/bin/ldconfig -f /etc/ld.so.conf -C ./etc/ld.so.cache -r . || true

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