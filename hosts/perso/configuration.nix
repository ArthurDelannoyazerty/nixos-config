{ pkgs, home-manager, ... }:

{
  # Basic system settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos-perso";
  time.timeZone = "Europe/Paris";

  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "fr";
  services.xserver.layout = "fr";
  services.xserver.xkbVariant = ""; 

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true; 
  # numpad ON in sddm
  services.displayManager.sddm.autoNumlock = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Define a user account
  users.users.arthur = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # sudo access
    shell = pkgs.bash;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages you want to install system-wide.
  environment.systemPackages = with pkgs; [
    git
    firefox
    vim
    curl
    wget
  ];

  # REUSABLE MODULES
  imports = [
    home-manager.nixosModules.home-manager

    ../../modules/home-manager
    ../../modules/hyprland
    ../../modules/terminal
    ../../modules/gaming
    ../../modules/dev
  ];
}