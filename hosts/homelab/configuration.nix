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
    # ../../modules/services/headscale.nix
    # ../../modules/services/headscale-ui.nix
    ../../modules/services/cloudflared.nix
    ../../modules/services/lldap.nix

    # --- APPS ---
    ../../modules/services/homepage.nix
    ../../modules/services/local-finance.nix
    # ../../modules/services/glances.nix
    ../../modules/services/power-monitor.nix
    ../../modules/services/vikunja.nix
    ../../modules/services/netdata.nix

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

  /* -------------------------------------------------------------------------- */
  /*                                POWER OPTIONS                               */
  /* -------------------------------------------------------------------------- */
  # Do not sleep when the lid is closed
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };
  };

  # Force the network card to stay awake
  networking.networkmanager.connectionConfig."connection.mdns" = 2; # Enable mDNS
  
  # Disable power management for the ethernet interface
  powerManagement.cpuFreqGovernor = "performance";
  
  # Specifically disable power management for the network interface
  systemd.services.disable-nic-powersave = {
    description = "Disable NIC Power Management";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.ethtool ];
    script = ''
      # Replace 'eth0' or 'enp...' with your actual interface name 
      # You can find it by running 'ip link'
      # This command disables 'Wake-on-LAN' power-down modes
      ethtool -s enp2s0 wol d || true 
    '';
  };

  /* -------------------------------------------------------------------------- */
  /*                            END OF POWER OPTIONS                            */
  /* -------------------------------------------------------------------------- */
  
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