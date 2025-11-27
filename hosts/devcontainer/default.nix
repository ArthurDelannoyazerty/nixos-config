{ pkgs, dotfilesInput, ... }: # <--- Add dotfilesInput here

let
  # 1. Prepare the dotfiles in a safe place (Read-Only in the image)
  dotfilesLayer = pkgs.runCommand "dotfiles-layer" { } ''
    mkdir -p $out/opt
    # Copy the dotfiles input to /opt/dotfiles
    cp -r ${dotfilesInput} $out/opt/dotfiles
  '';

  # 2. Create a "Startup Script" (Entrypoint)
  # This script runs every time the container starts.
  entrypointScript = pkgs.writeScriptBin "entrypoint.sh" ''
    #!${pkgs.bash}/bin/bash
    set -e

    DOTFILES_DIR="/home/arthur/.dotfiles"
    BACKUP_SOURCE="/opt/dotfiles"

    # Check if dotfiles are already installed in the PVC
    if [ ! -d "$DOTFILES_DIR" ]; then
      echo "--- First run detected: Installing Dotfiles ---"
      
      # Option A: Try to Git Clone (Best for updates/pushing)
      if git clone https://github.com/ArthurDelannoyazerty/dotfiles.git "$DOTFILES_DIR"; then
        echo "Git clone successful."
      else
        # Option B: Fallback to the baked-in files (Offline mode)
        echo "Git clone failed (no network?), using baked-in copy..."
        cp -rL "$BACKUP_SOURCE" "$DOTFILES_DIR"
        # Make them writable (copied from read-only store)
        chmod -R +w "$DOTFILES_DIR"
      fi

      # Run your setup script
      if [ -f "$DOTFILES_DIR/setup.sh" ]; then
        echo "Running setup.sh..."
        sh "$DOTFILES_DIR/setup.sh"
      fi
    fi

    # Execute the command passed to docker (usually /bin/bash)
    exec "$@"
  '';

  # 3. Existing Setup (User/Permissions)
  devSetup = pkgs.runCommand "dev-setup" { } ''
    mkdir -p $out/home/arthur
    mkdir -p $out/tmp
    mkdir -p $out/etc
    chmod 777 $out/home/arthur
    chmod 1777 $out/tmp
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
    util-linux
    
    # --- Terminal Tools ---
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

  config = {
    User = "arthur";
    WorkingDir = "/home/arthur";
    
    # Set the ENTRYPOINT to our script
    Entrypoint = [ "/bin/entrypoint.sh" ];
    
    # Default command (passed to entrypoint)
    Cmd = [ "/bin/bash" ];
    
    Env = [
      "USER=arthur"
      "HOME=/home/arthur"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PATH=/bin:/usr/bin:/usr/local/bin"
      "LANG=C.UTF-8"
      "LC_ALL=C.UTF-8"
    ];
  };
}