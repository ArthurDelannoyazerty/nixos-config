{ pkgs, ... }:

let
  # 1. Create a setup package that provides /etc/passwd and the directory structure
  devSetup = pkgs.runCommand "dev-setup" { } ''
    # Create the directory structure
    mkdir -p $out/home/arthur
    mkdir -p $out/tmp
    mkdir -p $out/etc

    # 1. Fix Permissions
    # We make the home directory writable by everyone (777).
    # Since we can't 'chown' files to arthue inside the Nix store (files are owned by root/nixbld),
    # making it writable ensures that when UID 1000 logs in, they can write to it 
    # (unless a PVC is mounted on top, in which case the PVC permissions rule).
    chmod 777 $out/home/arthur
    chmod 1777 $out/tmp

    # 2. Fix Identity (Create /etc/passwd and /etc/group)
    # This tells Linux that UID 1000 is "arthur" and Home is "/home/arthur"
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "arthur:x:1000:1000:Arthur:/home/arthur:/bin/bash" >> $out/etc/passwd
    
    echo "root:x:0:" > $out/etc/group
    echo "arthur:x:1000:" >> $out/etc/group
    
    # 3. Fix SSL/nsswitch (Standard for Nix containers to find DNS/Users)
    echo "hosts: files dns" > $out/etc/nsswitch.conf
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-devcontainer";
  tag = "latest";

  # Remove fakeRootCommands (It causes the build error you saw)
  # We handle permissions in 'devSetup' above.
  
  contents = with pkgs; [
    # Add our custom setup layer
    devSetup 
    
    # --- Base Utils ---
    bashInteractive
    coreutils
    git
    cacert
    curl
    wget
    iana-etc
    
    # --- From your modules/terminal ---
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
    User = "arthur"; # Now that /etc/passwd exists, we can use the name
    WorkingDir = "/home/arthur";
    Env = [
      "USER=arthur"
      "HOME=/home/arthur"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PATH=/bin:/usr/bin:/usr/local/bin"
      
      # Fix Local/Encoding issues (fixes btop error)
      "LANG=C.UTF-8"
      "LC_ALL=C.UTF-8"
    ];
    Cmd = [ "/bin/bash" ];
  };
}