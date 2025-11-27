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

    # --- 1. SETUP ENV ---
    mkdir -p ./usr/bin
    ln -sf ${pkgs.coreutils}/bin/env ./usr/bin/env

    # --- 2. SETUP LIBRARIES (The Heavy Lifting) ---
    mkdir -p ./usr/lib ./lib64

    # A. The Dynamic Loader (CRITICAL: VS Code cannot start without this)
    # This must be in /lib64 specifically
    ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ./lib64/ld-linux-x86-64.so.2

    # B. Bulk Link Libraries
    # Instead of picking files one by one, we link ALL libraries from these packages
    # into /usr/lib. This fixes libc, libstdc++, libgcc, libpthread, etc.
    
    find ${pkgs.glibc}/lib -name "*.so*" -exec ln -sf {} ./usr/lib/ \;
    find ${pkgs.stdenv.cc.cc.lib}/lib -name "*.so*" -exec ln -sf {} ./usr/lib/ \;
    
    # Optional: Add zlib/openssl if extensions fail later
    # find ${pkgs.zlib}/lib -name "*.so*" -exec ln -sf {} ./usr/lib/ \;

    # C. Compatibility Link (Your Suggestion)
    # Now that /usr/lib is full, we point /lib to it.
    ln -sfn ./usr/lib ./lib

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