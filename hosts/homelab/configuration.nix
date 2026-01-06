{ pkgs, home-manager, inputs, dotfiles, dotfilesDir, isLocal, nix-vscode-extensions, myConstants, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager    
    
    # hardware
    ./hardware-configuration.nix

    # modules
    ../../modules/nixos/base.nix
    ../../modules/nixos/server.nix

    ../../modules/terminal
    ../../modules/dev

    # --- INFRASTRUCTURE ---
    ../../modules/services/authentik.nix
    ../../modules/services/caddy.nix
    ../../modules/services/docker-socket-proxy.nix
    ../../modules/services/headscale.nix
    ../../modules/services/headscale-ui.nix
    ../../modules/services/cloudflared.nix
    ../../modules/services/ldap.nix

    # --- APPS ---
    ../../modules/services/homepage.nix
    ../../modules/services/local-finance.nix
    ../../modules/services/glances.nix
    ../../modules/services/power-monitor.nix
    ../../modules/services/vikunja.nix

    # Network services
    ../../modules/security-watchdog.nix   # Keeped to check that no port are open to internet
    
    # users
    ../../users/arthur-homelab/default.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs dotfiles dotfilesDir isLocal nix-vscode-extensions;
    };
  };

  # Basic system settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = false;

  networking.hostName = "nixos-homelab";
  networking.networkmanager.enable = true; 

  console.keyMap = "fr";

  # Do not sleep when the lid is closed
  services.logind.settings.Login = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
  };
  
  # Optional: Prevent the system from sleeping automatically due to inactivity
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Add 4GB of emergency swap memory  
  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 4096; # 4GB
  } ];

  
}