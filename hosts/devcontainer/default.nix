{ pkgs, ... }:

let
  # 1. We create a "package" that just contains the folder structure we need.
  # Nix will merge this into the root of the Docker image.
  dirSetup = pkgs.runCommand "dev-setup-dirs" { } ''
    mkdir -p $out/home/arthur
    mkdir -p $out/tmp
    chmod 1777 $out/tmp
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-devcontainer";
  tag = "latest";

  # 2. We add 'dirSetup' to the contents
  contents = with pkgs; [
    dirSetup # <--- This adds /home/arthur and /tmp
    
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
  ];

  # 3. Use fakeRootCommands ONLY for permissions (not creation)
  # '|| true' ensures the build doesn't crash if fakeroot acts weirdly, 
  # but since we mount a PVC at /home/arthur anyway, the PVC permissions will take over.
  fakeRootCommands = ''
    chown -R 1000:1000 /home/arthur || true
  '';

  config = {
    User = "1000";
    WorkingDir = "/home/arthur";
    Env = [
      "USER=arthur"
      "HOME=/home/arthur"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PATH=/bin:/usr/bin:/usr/local/bin"
    ];
    Cmd = [ "/bin/bash" ];
  };
}