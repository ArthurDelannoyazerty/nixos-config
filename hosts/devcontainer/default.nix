{ pkgs, ... }:

pkgs.dockerTools.buildLayeredImage {
  name = "nix-devcontainer";
  tag = "latest";
  
  # Created specifically for non-root usage (UID 1000)
  fakeRootCommands = ''
    mkdir -p /home/arthur
    chown 1000:1000 /home/arthur
    mkdir -p /tmp
    chmod 1777 /tmp
  '';

  contents = with pkgs; [
    # --- Base Utils ---
    bashInteractive
    coreutils
    git
    cacert  # Crucial for HTTPS (git clone, curl, etc)
    curl
    wget
    iana-etc # Fixes "unknown protocol" errors
    
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
    
    # --- Dev Tools (Mirroring your modules/dev) ---
    # Add the specific compilers/tools you need here
    vim
    python3
    uv
    nodejs
    gnumake
    gcc
    ripgrep
    fd
    
    # --- Nix itself (Optional) ---
    # Useful if you want to run 'nix flake check' inside the container
    # Note: Requires multi-user daemon setup usually, strictly basic here.
    nix 
  ];

  config = {
    # Run as the standard non-root user (usually mapped to 1000 in K8s/Rancher)
    User = "1000";
    
    # This matches your PVC mount point logic
    WorkingDir = "/home/arthur";
    
    # Set up environment variables
    Env = [
      "USER=arthur"
      "HOME=/home/arthur"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      # Nix automatically handles PATH, but we ensure /bin is there
      "PATH=/bin:/usr/bin:/usr/local/bin"
    ];
    
    # Default command when container starts
    Cmd = [ "/bin/bash" ];
  };
}