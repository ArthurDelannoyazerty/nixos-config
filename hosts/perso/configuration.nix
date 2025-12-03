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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-perso";

  console.keyMap = "fr";
  services.xserver.layout = "fr";
  services.xserver.xkbVariant = ""; 

  services.getty.autologinUser = "arthur";

  environment.systemPackages = with pkgs; [
    firefox
  ];

}