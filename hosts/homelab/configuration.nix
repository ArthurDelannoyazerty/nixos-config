{ pkgs, home-manager, inputs, dotfiles, dotfilesDir, isLocal, nix-vscode-extensions, myConstants, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager    
    
    /* -------------------------------- HARDWARE -------------------------------- */
    ./hardware-configuration.nix

    /* ----------------------------- GENERIC MODULES ---------------------------- */
    ../../modules/nixos/base.nix
    ../../modules/nixos/server.nix

    ../../modules/terminal
    ../../modules/dev

    /* ---------------------------------- MEDIA --------------------------------- */
    ./services/media/byparr.nix
    ./services/media/cleanuparr.nix
    ./services/media/filebrowser-quantum.nix 
    ./services/media/immich.nix
    ./services/media/jellyfin.nix
    ./services/media/komga.nix
    ./services/media/onlyoffice.nix
    ./services/media/piped.nix
    ./services/media/prowlarr.nix
    ./services/media/qbittorrent.nix
    ./services/media/recyclarr.nix
    ./services/media/seer.nix
    ./services/media/sonarr.nix
    ./services/media/suwayomi.nix
    ./services/media/tranga.nix


    /* ------------------------------- MONITORING ------------------------------- */
    ./services/monitoring/alloy.nix 
    ./services/monitoring/borgmatic.nix
    ./services/monitoring/grafana.nix 
    ./services/monitoring/loki.nix
    ./services/monitoring/netdata.nix
    ./services/monitoring/power-monitor.nix
    ./services/monitoring/prometheus.nix 
    # ./services/random/scanopy.nix     # Disabled because not really useful
    ./services/monitoring/scrutiny.nix
    ./services/monitoring/uptime-kuma.nix

    /* --------------------------------- RANDOM --------------------------------- */
    ./services/random/crafty-controller.nix 
    ./services/random/forgejo.nix 
    ./services/random/homepage.nix
    ./services/random/local-finance.nix
    ./services/random/n8n.nix 
    ./services/random/quartz.nix  
    ./services/random/romm.nix      
    ./services/random/security-watchdog.nix
    ./services/random/stirling-pdf.nix
    ./services/random/vert.nix
    ./services/random/vikunja.nix
    ./services/random/wanderer.nix

    /* -------------------------------- SECURITY -------------------------------- */
    ./services/security/authentik.nix
    ./services/security/caddy.nix
    ./services/security/cloudflared.nix
    ./services/security/docker-socket-proxy.nix
    ./services/security/gluetun.nix
    ./services/security/lldap.nix
    
    /* ---------------------------------- USERS --------------------------------- */
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
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  console.keyMap = "fr";


  
  boot.kernelModules = [ 
    # CPU temps
    "coretemp" 
    # Load the actual INTEL HARDWARE WATCHDOG
    "iTCO_wdt" 
  ];

  /* -------------------------------------------------------------------------- */
  /*                                POWER OPTIONS                               */
  /* -------------------------------------------------------------------------- */
  # LOGIND: Correct NixOS syntax to prevent lid-close suspension
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  # SYSTEMD: Disable all sleep targets
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # KERNEL
  boot.kernelParams = [
    # Disable Display C-States and Panel Self-Refresh. 
    # This prevents the SoC electrical deadlock when no monitor is attached.
    "i915.enable_dc=0"
    "i915.enable_psr=0"

    # Disable SATA Link Power Management (fixes SATA/NVMe controller lockups)
    "ahci.mobile_lpm_policy=1"

    # Disable Active State Power Management for PCIe
    "pcie_aspm=off"

    # Prevent deep CPU sleep states that cause "fainting"
    "intel_idle.max_cstate=7"
    
    # Disable NVMe power management (often causes freezes on cheap SSDs)
    "nvme_core.default_ps_max_latency_us=0"

    # Emergency: Reboot the computer automatically 10 seconds after a crash
    "panic=10"
    "oops=panic"
    "nmi_watchdog=panic"
    "softlockup_panic=1"
  ];

  # This uses a "Dead Man's Switch". If the CPU freezes, the hardware 
  # will notice the lack of "ticks" and force a reboot.
  # Configure systemd to use the hardware watchdog (More reliable than watchdogd)
  services.watchdogd.enable = false; # Disable the external daemon
  systemd.settings.Manager.RuntimeWatchdogSec = "20s"; # systemd will pet the HW watchdog every 10s
  systemd.settings.Manager.RebootWatchdogSec = "1m";   # If systemd hangs for 1m, the motherboard cuts power

  # 4. NETWORK: Disable standard power management
  powerManagement.enable = false; # Global disable
  
  # Prevent NetworkManager from putting WiFi/Ethernet to sleep
  networking.networkmanager.wifi.powersave = false;

  # Ensure Intel Microcode is updated (fixes low-level CPU bugs)
  hardware.cpu.intel.updateMicrocode = true;

  # ETHTOOL: Explicitly disable Energy Efficient Ethernet (EEE)
  # Note: Requires 'ethtool' in system packages
  environment.systemPackages = [ pkgs.ethtool ];

  # Prevent Swap Thrashing lockups by enabling systemd-oomd
  # This kills memory-hogging apps before they lock up the entire system
  systemd.oomd.enable = true;
  
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