# /modules/nixos/server.nix
{ pkgs, ... }:

{
  # Enable OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no"; # Only allow user login
    };
  };

  # Tailscale: The easiest way to access your homelab securely from anywhere
  services.tailscale.enable = true;
  networking.firewall.checkReversePath = "loose";
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

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
    ctop          # Top-like interface for container metrics
  ];
  
}