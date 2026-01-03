# /modules/nixos/base.nix
{ pkgs, ... }:

{
  # Basic system settings
  system.stateVersion = "25.05";
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable networking
  networking.networkmanager.enable = true;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # run dynamically linked binaries 
  programs.nix-ld.enable = true;

  # Install common system-wide packages
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    openssl
  ];
}