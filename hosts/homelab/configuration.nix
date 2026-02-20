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
    # ../../modules/services/filebrowser.nix
    ../../modules/services/scrutiny.nix
    ../../modules/services/uptime-kuma.nix

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

  # CPU temps
  boot.kernelModules = [ "coretemp" ];

  /* -------------------------------------------------------------------------- */
  /*                                POWER OPTIONS                               */
  /* -------------------------------------------------------------------------- */
  # 1. LOGIND: Correct NixOS syntax to prevent lid-close suspension
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  # 2. SYSTEMD: Disable all sleep targets (You had this right)
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # 3. KERNEL
  boot.kernelParams = [
    # Emergency: Reboot the computer automatically 10 seconds after a crash
    "panic=10"
    "oops=panic"
    "nmi_watchdog=panic"
    "softlockup_panic=1"
    
    # Disable Active State Power Management (ASPM) to stop PCI devices 
    "pcie_aspm=off"
  ];

  # This uses a "Dead Man's Switch". If the CPU freezes, the hardware 
  # will notice the lack of "ticks" and force a reboot.
  services.watchdogd.enable = true;


  # 4. NETWORK: Disable standard power management
  powerManagement.enable = false; # Global disable
  
  # Prevent NetworkManager from putting WiFi/Ethernet to sleep
  networking.networkmanager.wifi.powersave = false;

  

  # 5. ETHTOOL: Explicitly disable Energy Efficient Ethernet (EEE)
  # Note: Requires 'ethtool' in system packages
  environment.systemPackages = [ pkgs.ethtool ];
  
  systemd.services.disable-nic-energy-saving = {
    description = "Disable Ethernet Energy Saving (EEE)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # CHANGE THIS NAME to what you found in Step 1 (e.g. eno1, eth0)
      INTERFACE="eno1"
      
      # Check if interface exists before running command to avoid errors
      if [ -d "/sys/class/net/$INTERFACE" ]; then
        ${pkgs.ethtool}/bin/ethtool --set-eee $INTERFACE eee off || true
        echo "Disabled EEE for $INTERFACE"
      else
        echo "Interface $INTERFACE not found, skipping EEE disable."
      fi
    '';
  };

  /* -------------------------------------------------------------------------- */
  /*                            END OF POWER OPTIONS                            */
  /* -------------------------------------------------------------------------- */
  

  # Add 4GB of emergency swap memory  
  swapDevices = [ {
    device = "/var/lib/swapfile";
    size = 4096; # 4GB
  } ];

  
}