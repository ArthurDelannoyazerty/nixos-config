{ pkgs, config, inputs, dotfiles, dotfilesDir, isLocal, nix-vscode-extensions, ... }:

let
  # Define a helper function named 'link'
  link = path:
    if isLocal then
      # If local repo exists, use mkOutOfStoreSymlink (Mutuable / Editable)
      # This points directly to /home/arthur/dotfiles/...
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}"
    else
      # Otherwise, use the store copy (Immutable / Safe for new installs)
      "${dotfiles}/${path}";

  # Access the community extension marketplace
  marketplace = pkgs.vscode-marketplace; 
in

{
  imports = [
    ../../modules/home-manager/vscode.nix
    ../../modules/home-manager/shell.nix
  ];

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
  # This needs to be set for Home Manager to work correctly
  home.stateVersion = "25.05";

  # Set your home directory and username
  home.username = "arthur";
  home.homeDirectory = "/home/arthur";

  # Packages to install in your user profile
  home.packages = with pkgs; [
    # Fonts
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term

    papirus-icon-theme

    brightnessctl    # For laptop brightness keys

    swayosd     # On-screen display for brightness/volume changes 
  ];

  # set the hyprland.conf to the right place
  # Note: We use the 'link' function and pass the path relative to the repo root
  xdg.configFile."hypr/hyprland.conf".source = link "hyprland/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = link "hyprlock/hyprlock.conf";
  xdg.configFile."rofi/config.rasi".source = link "rofi/config.rasi";
  
  # pureline
  home.file.".pureline.job.conf".source      = link "pureline/.pureline.job.conf";
  home.file.".pureline.personal.conf".source = link "pureline/.pureline.personal.conf";

  # VSCode
  xdg.configFile."Code/User/settings.json".source = link "codium/settings.json";
  xdg.configFile."Code/User/settings.json".force  = true;
  xdg.configFile."Code/User/keybindings.json".source = link "codium/keybindings.json";
  xdg.configFile."Code/User/keybindings.json".force  = true;

  # Waybar
  xdg.configFile."waybar/config.jsonc".source = link "waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source = link "waybar/style.css";

  # polkit daemon
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit.Description = "polkit-gnome-authentication-agent-1";
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

}