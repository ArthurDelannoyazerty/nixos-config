{ pkgs, ... }:

{
  # Basic system settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos-perso";
  time.timeZone = "Europe/Paris";

  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

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
    ../../modules/home-manager
    ../../modules/hyprland
    ../../modules/terminal
    ../../modules/gaming
    ../../modules/dev
  ];
}