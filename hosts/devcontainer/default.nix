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
    # This ensures Up Arrow stays as normal Bash history
    # and Ctrl-R opens Atuin
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

  fakeRootCommands = ''
    mkdir -p ./home/arthur
    mkdir -p ./tmp

    # --- 1. FHS DIRECTORY STRUCTURE ---
    # We create /usr/lib and make everyone else point to it.
    # This matches standard Linux (Ubuntu/Debian) behavior.
    mkdir -p ./usr/lib ./usr/bin
    ln -s usr/lib lib
    ln -s usr/lib lib64
    ln -s lib usr/lib64

    # --- 2. SETUP /usr/bin/env ---
    # Required for VS Code scripts
    ln -sf ${pkgs.coreutils}/bin/env ./usr/bin/env

    # --- 3. POPULATE LIBRARIES ---
    
    # A. The Dynamic Loader (The "Brain")
    # VS Code looks for /lib64/ld-linux-x86-64.so.2
    # Since /lib64 -> /usr/lib, we link it there.
    ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ./usr/lib/ld-linux-x86-64.so.2

    # B. The C++ Standard Library (The Error You Are Seeing)
    # We use 'find' to locate it regardless of whether it's in /lib or /lib64 inside the Nix store
    find ${pkgs.stdenv.cc.cc.lib} -name "libstdc++.so.6*" -exec ln -sf {} ./usr/lib/ \;

    # C. The C Standard Library (glibc)
    # Linking all .so files from glibc to /usr/lib
    find ${pkgs.glibc}/lib -name "*.so*" -exec ln -sf {} ./usr/lib/ \;
    
    # D. GCC Libs (libgcc_s.so.1)
    # Often needed alongside libstdc++
    find ${pkgs.stdenv.cc.cc.lib} -name "libgcc_s.so.1" -exec ln -sf {} ./usr/lib/ \;

    # ----------------------------------------------

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
      # Explicitly set history file location for Bash
      "HISTFILE=/home/arthur/.bash_history"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PATH=/bin:/usr/bin:/usr/local/bin"
      "LANG=C.UTF-8"
      "LC_ALL=C.UTF-8"
      "ATUIN_CONFIG_DIR=/etc/atuin" 
    ];
  };
}