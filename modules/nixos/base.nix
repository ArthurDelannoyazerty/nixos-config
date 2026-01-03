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


  # Add binary caches to speed up downloads
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}