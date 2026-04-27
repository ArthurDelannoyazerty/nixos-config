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

    # Only Office fonts
    corefonts
    vista-fonts

    papirus-icon-theme

    brightnessctl    # For laptop brightness keys

    swayosd     # On-screen display for brightness/volume changes 

    reversal-icon-theme

    bitwarden-desktop
    obsidian
    tailscale
    onlyoffice-desktopeditors
    kdePackages.kdenlive

    baobab
  ];

  # File explorer TUI
  programs.yazi.enable = true;

  # Hyprland cursor
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };
  gtk.enable = true;
  qt = {
    enable = true;
    platformTheme.name = "qtct"; # This tells Nix to handle the integration
    style.name = "kvantum";      # Kvantum is generally the best for Hyprland aesthetics
  };

  # Hide rofi menu items
  xdg.desktopEntries = {
    # Hide htop from the application menu
    htop = {
      name = "htop";
      noDisplay = true;
    };
    # Add any other CLI apps that keep showing up here
    btop = {
      name = "btop";
      noDisplay = true;
    };
    nvtop = {
      name = "nvtop";
      noDisplay = true;
    };
    kvantummanager = {
      name = "Kvantum Manager";
      noDisplay = true;
    };
    # The NixOS manual often has a specific ID
    "nixos-manual" = {
      name = "NixOS Manual";
      noDisplay = true;
    };

    qt5ct = {
      name = "Qt5 Settings";
      noDisplay = true;
    };
    qt6ct = {
      name = "Qt6 Settings";
      noDisplay = true;
    };

    rofi = {
      name = "Rofi";
      noDisplay = true;
    };
    "rofi-drun" = {
      name = "Rofi Drun";
      noDisplay = true;
    };
    "rofi-theme-selector" = {
      name = "Rofi Theme Selector";
      noDisplay = true;
    };


  };

  gtk.iconTheme = {
    name = "Reversal-black-dark";
    package = pkgs.reversal-icon-theme;
  };

  # set the hyprland.conf to the right place
  # Note: We use the 'link' function and pass the path relative to the repo root
  xdg.configFile."hypr/hyprland.conf" = {
    source = link "hyprland/hyprland.conf";
    force = true;
  };
  # Modular hyprland conf
  xdg.configFile."hypr/conf" = {
    source = link "hyprland/conf";
    force = true;
  };
  xdg.configFile."hypr/hyprlock.conf" = {
    source = link "hyprlock/hyprlock.conf";
    force = true;
  };
  xdg.configFile."rofi/config.rasi" = {
    source = link "rofi/config.rasi";
    force = true;
  };

  # VSCode
  xdg.configFile."Code/User/settings.json" = {
    source = link "codium/settings.json";
    force  = true;
  };
  xdg.configFile."Code/User/keybindings.json" = {
    source = link "codium/keybindings.json";
    force  = true;
  };


  # Waybar
  xdg.configFile."waybar/config.jsonc" = {
    source = link "waybar/config.jsonc";
    force = true;
  };
  xdg.configFile."waybar/style.css" = {
    source = link "waybar/style.css";
    force = true;
  };

  # Wlogout
  xdg.configFile."wlogout/layout" = {
    source = link "wlogout/layout";
    force = true;
  };
  xdg.configFile."wlogout/style.css" = {
    source = link "wlogout/style.css";
    force = true;
  };

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