# /modules/nixos/server.nix
{ pkgs, ... }:

{
  # Enable OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      # Hardening: Disable password auth, force keys
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no"; # Only allow user login
    };
  };

  # Tailscale: The easiest way to access your homelab securely from anywhere
  services.tailscale.enable = true;
  # Allow the magic DNS to work
  networking.firewall.checkReversePath = "loose";

  virtualisation.oci-containers.backend = "docker";

  # Useful Homelab/Server CLI Tools
  environment.systemPackages = with pkgs; [
    # Network Debugging
    dig           # DNS lookup
    tcpdump       # Packet analyzer
    nmap          # Network scanner (check open ports)
    ethtool       # Network card config

    # Disk/System Management
    iotop         # I/O usage monitor (like top for disk)
    lm_sensors    # CPU temp / fan speeds
    smartmontools # Check HDD/SSD health (S.M.A.R.T)
    parted        # Disk partitioning

    # Container Management
    lazydocker    # Terminal UI for Docker (VERY useful)
    docker-compose # Standard compose
    ctop          # Top-like interface for container metrics
  ];
  
  # 5. Open Firewall ports
  networking.firewall.allowedTCPPorts = [ 
    22   # SSH
    80   # HTTP (for reverse proxies)
    443  # HTTPS
  ];
}