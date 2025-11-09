{ pkgs, ... }:

{
  # Basic system settings for a server
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos-homelab"; # Set a unique hostname
  time.timeZone = "Etc/UTC"; # Servers often use UTC

  # Define your user account
  users.users.your-user = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # For sudo access
    shell = pkgs.bash;
  };

  # =========================================================================
  # == SERVER CONFIGURATION
  # =========================================================================

  # Enable the OpenSSH daemon for remote access
  services.openssh.enable = true;

  # Configure the firewall to only allow SSH connections
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  # This is a server, so we don't need sound or a graphical interface
  sound.enable = false;
  services.xserver.enable = false;

  # System-wide packages for server administration
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    wget
  ];

  # =========================================================================
  # == IMPORT REUSABLE MODULES
  #    We only import the modules relevant for a headless server.
  # =========================================================================
  imports = [
    home-manager.nixosModules.home-manager

    ../../modules/home-manager  # To manage your dotfiles
    ../../modules/terminal      # For a consistent shell experience
  ];
}