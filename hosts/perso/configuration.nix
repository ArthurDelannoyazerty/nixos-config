{ pkgs, home-manager, lib, config, inputs, dotfiles, dotfilesDir, isLocal, nix-vscode-extensions, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager    
    
    # hardware
    ./hardware-configuration.nix

    # modules
    ../../modules/nixos/base.nix
    ../../modules/nixos/sound.nix
    ../../modules/terminal
    ../../modules/dev
    ../../modules/hyprland
    ../../modules/gaming
    ../../modules/gaming/minecraft.nix

    # users
    ../../users/arthur-perso/default.nix
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
  boot.loader.systemd-boot.enable = false;    # Prefer grub
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";           # "nodev" is required for EFI systems
    useOSProber = true;         # Automatically detects Windows and other OS

    extraEntries = ''
      menuentry "BIOS / UEFI Settings" --class uefi {
        fwsetup
      }
    '';
  };

  boot.loader.grub2-theme = {
    enable = true;
    theme = "vimix";         # Choose between: "tela", "vimix", "stylish", or "whitesur"
    footer = true;           # Displays a nice footer at the bottom
    screen = "1080p";        # Choose resolution: "1080p", "2k", "4k", "ultrawide", or "ultrawide2k"
    icon = "white";          # Choose icon style: "color", "white", or "whitesur"
  };


  networking.hostName = "nixos-perso";

  console.keyMap = "fr";
  services.xserver.xkb.layout  = "fr";
  services.xserver.xkb.variant = ""; 

  services.getty.autologinUser = "arthur";

  environment.systemPackages = with pkgs; [
    firefox

    # Add support for common USB/SD card filesystems
    udiskie
    exfatprogs  # For exFAT
    ntfs3g      # For NTFS
    usbutils    # Useful for 'lsusb'

    # File manager
    nautilus
    
    grim          # Image capture
    slurp         # Interactive selection
    wf-recorder  # Video capture
    jq            # JSON parser 
    wl-clipboard  # Clipboard support
    libnotify     # Desktop notifications

    imv     # image viewer
    mpv     # video viewer
  ];

  environment.sessionVariables = {
    # Fix for NVIDIA on Wayland
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    
    # Force Firefox to use Wayland mode
    MOZ_ENABLE_WAYLAND = "1";

    # Required for Electron apps (Discord, VS Code) to run natively on Wayland
    NIXOS_OZONE_WL = "1";

    # Forces Firefox to use the NVIDIA backend for its internal compositor
    NVD_BACKEND = "direct";
    
    # Ensure Firefox doesn't use the old GLX path
    MOZ_DISABLE_RDD_SANDBOX = "1";
    EGL_PLATFORM = "wayland";
    
    # NVIDIA specific Wayland fixes
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
  };
  boot.kernelParams = [ "nvidia_drm.modeset=1" "nvidia_drm.fbdev=1" ];

  # Force CPU to prioritize performance over power saving
  powerManagement.cpuFreqGovernor = "performance";


  services.tailscale.enable = true;

  # nct6775 & coretemp for fans & temperature sensors
  # wl for wifi card
  boot.kernelModules = [ "nct6775" "coretemp" "wl" ];


  # Wifi
  # Tell NixOS to permit unfree packages and specific insecure dependencies
  nixpkgs.config = {
    allowUnfree = true; 
    permittedInsecurePackages = [
      "electron-39.8.10"
      "broadcom-sta-6.30.223.271-59-6.18.34"
    ];
  };

  boot.extraModulePackages =[ config.boot.kernelPackages.broadcom_sta ];
  # Blacklist the open-source drivers so they stop hijacking the card
  boot.blacklistedKernelModules =[ "b43" "bcma" "brcmfmac" "brcmsmac" "ssb" ];
  # Tell the country to activate the dual band for the wifi card
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=FR
  '';
  hardware.wirelessRegulatoryDatabase = true;

  # Utility lib that can mount volumes
  services.udisks2.enable = true;
  # Lib that trigger th volume mount when a new volume is detected
  services.gvfs.enable = true;

  # Add support for common USB/SD card filesystems
  boot.supportedFilesystems = [ "ntfs" "exfat" ];


  # Dolphin fix
  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "breeze";
  };


}