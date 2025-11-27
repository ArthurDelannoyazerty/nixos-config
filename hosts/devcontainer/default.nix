{ pkgs, dotfilesInput, ... }:

let
  # 1. Dotfiles Storage (Read-Only)
  dotfilesLayer = pkgs.runCommand "dotfiles-layer" { } ''
    mkdir -p $out/opt
    cp -r ${dotfilesInput} $out/opt/dotfiles
  '';

  # 2. Entrypoint Script
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

  # 3. System Config (Passwd/Group)
  # We ONLY do /etc files here. We do NOT create /home here.
  devSetup = pkgs.runCommand "dev-setup" { } ''
    mkdir -p $out/etc
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "arthur:x:1000:1000:Arthur:/home/arthur:/bin/bash" >> $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
    echo "arthur:x:1000:" >> $out/etc/group
    echo "hosts: files dns" > $out/etc/nsswitch.conf

    # --- bash-preexec Symlink (ATUIN) ---
    # We create the standard directory
    mkdir -p $out/usr/share/bash-preexec
    
    # We link the file from the Nix store to the standard path
    ln -s ${pkgs.bash-preexec}/share/bash-preexec/bash-preexec.sh $out/usr/share/bash-preexec/bash-preexec.sh
  '';

in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-devcontainer";
  tag = "latest";

  contents = with pkgs; [
    devSetup
    dotfilesLayer      # <--- The baked-in files
    entrypointScript   # <--- The script to install them
    
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

    # --- 4. ESSENTIAL LINUX TOOLS (ADDED) ---
    gnugrep   # Fixes 'grep: command not found'
    gnused    # Essential for scripts (sed)
    findutils # Essential for scripts (find, xargs)
    gawk      # awk
    which     # Useful to check paths
    util-linux
    
    # --- Terminal Tools ---
    bash-preexec
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
  # 4. FIX PERMISSIONS HERE
  # We use relative paths (./home) because this script runs in the build root.
  fakeRootCommands = ''
    mkdir -p ./home/arthur
    mkdir -p ./tmp

    # Set ownership to 1000 (arthur)
    chown -R 1000:1000 ./home/arthur
    chown -R 1000:1000 ./tmp
    
    # Set permissions (Owner can write)
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
      "HISTFILE=/home/arthur/.bash_history"
      "BASH_PREEXEC_PATH=${pkgs.bash-preexec}/share/bash-preexec/bash-preexec.sh"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PATH=/bin:/usr/bin:/usr/local/bin"
      "LANG=C.UTF-8"
      "LC_ALL=C.UTF-8"
      "ATUIN_NO_SYNC=true"
    ];
  };
}