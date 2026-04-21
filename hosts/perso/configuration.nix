{ pkgs, home-manager, inputs, dotfiles, dotfilesDir, isLocal, nix-vscode-extensions, ... }:

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
  ];

  services.tailscale.enable = true;

  boot.kernelModules = [ "nct6775" "coretemp" ];

}