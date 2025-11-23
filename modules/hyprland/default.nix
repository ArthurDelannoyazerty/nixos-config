# /modules/hyprland/default.nix
{ pkgs, inputs, ... }:

{

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # XDG Portal Configuration
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk # Needed for file pickers & fallback
    ];
    # Force apps to look at Hyprland for screen sharing, and GTK for files
    config.common.default = [ "hyprland" ];
  };

  # Install related packages
  environment.systemPackages = with pkgs; [
    waybar
    rofi
    kitty
    hyprlock
    polkit_gnome  # authentification popup

    wl-clipboard  # Clipboard support for Wayland
    dunst         # Notification daemon
    grim          # Screenshot tool (region)
    slurp         # Screenshot tool (selector)
  ];


    security.polkit.enable = true;
}