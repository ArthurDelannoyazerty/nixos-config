# /modules/hyprland/default.nix
{ pkgs, inputs, ... }:

{
  # Enable the XDG portal for Hyprland for screen sharing, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Install related packages
  environment.systemPackages = with pkgs; [
    waybar
    rofi
    kitty
  ];
}