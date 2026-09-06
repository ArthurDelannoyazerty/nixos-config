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

    # users (Applies your shared home.nix!)
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
    theme = "vimix";
    footer = true;
    screen = "1080p";
    icon = "white";
  };

  networking.hostName = "nixos-portable";

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

    # ---------------------------------------------------------
    # File manager: Synced with your perso config (Nemo)
    # ---------------------------------------------------------
    file-roller            # GNOME Archive manager (Extract zip/tar files directly)
    ffmpegthumbnailer      # Video thumbnails
    evince                 # PDF viewer (and provides PDF thumbnails)
    libgsf                 # Office document thumbnails (Word, Excel)
    webp-pixbuf-loader     # WebP image thumbnails
    poppler                # PDF rendering
    nemo-with-extensions 
    nemo-preview      
    adw-gtk3

    # Hyprland utilities
    grim          # Image capture
    slurp         # Interactive selection
    wf-recorder   # Video capture
    jq            # JSON parser 
    wl-clipboard  # Clipboard support
    libnotify     # Desktop notifications
    imv           # image viewer

    # Note: mpv is removed here because your home.nix installs it with custom scripts
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  # ---------------------------------------------------------
  # Wayland Environment Variables (Cleaned of NVIDIA params)
  # ---------------------------------------------------------
  environment.sessionVariables = {
    # Force Firefox to use Wayland mode
    MOZ_ENABLE_WAYLAND = "1";
    # Required for Electron apps (Discord, VS Code) to run natively on Wayland
    NIXOS_OZONE_WL = "1";
    EGL_PLATFORM = "wayland";
  };

  # ---------------------------------------------------------
  # Power Management for Laptop Battery Life
  # ---------------------------------------------------------
  # TLP is an excellent, set-and-forget power management tool for Linux laptops.
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    };
  };
  # Disable power-profiles-daemon as it conflicts with TLP
  services.power-profiles-daemon.enable = false;

  services.tailscale.enable = true;

  # Removed "wl" (broadcom driver) and kept temp sensors
  boot.kernelModules = [ "nct6775" "coretemp" ];

  # Utility lib that can mount volumes & trigger mounts
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Add support for common USB/SD card filesystems
  boot.supportedFilesystems = [ "ntfs" "exfat" ];

  # ---------------------------------------------------------
  # Flatpak & Bitwarden (Required for your home.nix SSH config)
  # ---------------------------------------------------------
  services.flatpak = {
    enable = true;
    remotes = [{ name = "flathub"; location = "https://dl.flathub.org/repo/flathub.flatpakrepo"; }];
    packages = [ "com.bitwarden.desktop" ];
    update.auto.enable = true;

    overrides = {
      "com.bitwarden.desktop" = {
        Environment = {
          BITWARDEN_SSH_AUTH_SOCK = "/home/arthur/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock";
        };
      };
    };
  };
}