{ pkgs, config, inputs, dotfiles, dotfilesDir, isLocal, nix-vscode-extensions, osConfig, ... }:

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

  # Define the auto-start script conditionally.
  # Safely check if Hyprland is even declared before checking if it's enabled.
  hyprlandAutoStart = if (osConfig.programs ? hyprland && osConfig.programs.hyprland.enable) then ''
    # Start Hyprland automatically if in TTY1
    if [ -z "$DISPLAY" ] &&[ "$(tty)" = "/dev/tty1" ]; then
      exec start-hyprland
    fi
  '' else "";
in

{
  # Let Home Manager manage itself
  programs.home-manager.enable = true;
  # This needs to be set for Home Manager to work correctly
  home.stateVersion = "25.05";

  # Set your home directory and username
  home.username = "arthur";
  home.homeDirectory = "/home/arthur";

  # Packages to install in your user profile
  home.packages = with pkgs;[
    # Fonts
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
    inter

    # Only Office fonts
    corefonts
    vista-fonts

    papirus-icon-theme

    brightnessctl    # For laptop brightness keys

    swayosd     # On-screen display for brightness/volume changes 

    reversal-icon-theme
    tela-circle-icon-theme

    bitwarden-desktop
    obsidian
    tailscale
    onlyoffice-desktopeditors
    kdePackages.kdenlive

    baobab

    crosspipe

    # CLI Tools (Migrated from shell.nix)
    btop
    tree
    nvitop
    bash-preexec

    # hyprland
    awww
    matugen
    adwaita-icon-theme

    imagemagick
  ];

  /* -------------------------------------------------------------------------- */
  /*                                SHELL CONFIGS                               */
  /* -------------------------------------------------------------------------- */

  programs.kitty = {
    enable = true;
    font = {
      name = "IosevkaTerm Nerd Font Mono";
      size = 12;
    };
    settings = {
      window_padding_width = 4;
      confirm_os_window_close = 0;
    };
  };

  programs.bash = {
    enable = true;
    initExtra = ''
      # Insert the conditional Hyprland script here
      ${hyprlandAutoStart}

      # Logic to choose the right path for bash sourcing
      if [ -f "${dotfilesDir}/bash/.bashrc" ]; then
        source "${dotfilesDir}/bash/.bashrc"
      elif [ -f "${dotfiles}/bash/.bashrc" ]; then
        source "${dotfiles}/bash/.bashrc"
      fi

      # Append to history file immediately, don't overwrite it
      shopt -s histappend
    '';
  };

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      auto_sync = false;
      update_check = false;
      sync_address = "";
      style = "compact";
      inline_height = 10;
      show_preview = true;
    };
  };

  # Dunst notification daemon
  services.dunst = {
    enable = true;
  };

  /* -------------------------------------------------------------------------- */
  /*                                   VSCODE                                   */
  /* -------------------------------------------------------------------------- */

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = false;   # Nix controls the extensions

    profiles.default.extensions = (with marketplace;[
      # === PYTHON ===
      ms-python.python
      ms-python.debugpy
      ms-python.vscode-pylance
      ms-python.vscode-python-envs
      charliermarsh.ruff
      njpwerner.autodocstring
      njqdev.vscode-python-typehint
      ms-toolsai.jupyter
      ms-toolsai.jupyter-keymap
      ms-toolsai.jupyter-renderers
      ms-toolsai.vscode-jupyter-cell-tags
      
      # === AI ===
      continue.continue
      google.geminicodeassist

      # === GIT ===
      eamodio.gitlens
      mhutchie.git-graph
      ms-vscode.azure-repos

      # === THEMES & ICONS ===
      pkief.material-icon-theme
      monokai.theme-monokai-pro-vscode
      nicolaiverbaarschot.alabaster-variant-theme
      tonsky.theme-alabaster
      johnpapa.vscode-peacock
      fxzer.theme-vitesse-dark-custom


      # === TOOLS ===
      esbenp.prettier-vscode
      mechatroner.rainbow-csv
      hediet.vscode-drawio
      mermaidchart.vscode-mermaid-chart
      jnoortheen.nix-ide
      christian-kohler.path-intellisense
      ritwickdey.liveserver
      tomoki1207.pdf
      stackbreak.comment-divider
      torreysmith.copyfilepathandcontent
      irongeek.vscode-env
      emilast.logfilehighlighter
      alexcvzz.vscode-sqlite
      qwtel.sqlite-viewer
      rioj7.command-variable
      
      # === MISC ===
      codediagram.codediagram 
      marketplace."076923".python-image-preview 
    ]) ++ (with pkgs.vscode-extensions;[
      # === REMOTE & SSH ===
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-vscode.remote-explorer
      ms-vscode-remote.remote-containers
    ]);
  };


  /* -------------------------------------------------------------------------- */
  /*                               DORFILES LINKS                               */
  /* -------------------------------------------------------------------------- */
  # VSCode dotfiles Links
  xdg.configFile."Code/User/settings.json" = {
    source = link "code/settings.json";
    force  = true;
  };
  xdg.configFile."Code/User/keybindings.json" = {
    source = link "code/keybindings.json";
    force  = true;
  };
  xdg.configFile."Code/User/launch.json" = {
    source = link "code/launch.json";
    force  = true;
  };

  # Starship dotfiles link
  xdg.configFile."starship.toml" = {
    source = link "starship/starship.toml";
    force = true;
  };

  /* -------------------------------------------------------------------------- */
  /*                                 UI / DESKTOP                               */
  /* -------------------------------------------------------------------------- */

  # Hyprland cursor
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = "Tela-circle-dark"; 
      package = pkgs.tela-circle-icon-theme;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    # Silence the warning & let GTK4 apps use native Libadwaita
    gtk4.theme = null;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct"; # This tells Nix to handle the integration
    style.name = "kvantum";      # Kvantum is generally the best for Hyprland aesthetics
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "nemo.desktop" ];
      "application/x-gnome-saved-search" = [ "nemo.desktop" ];
    };
  };

  dconf.settings = {
    "org/cinnamon/desktop/applications/terminal" = {
      exec = "kitty";
    };
  };

  # Hide rofi menu items
  xdg.desktopEntries = {
    htop = { name = "htop"; noDisplay = true; };
    btop = { name = "btop"; noDisplay = true; };
    nvtop = { name = "nvtop"; noDisplay = true; };
    kvantummanager = { name = "Kvantum Manager"; noDisplay = true; };
    "nixos-manual" = { name = "NixOS Manual"; noDisplay = true; };
    qt5ct = { name = "Qt5 Settings"; noDisplay = true; };
    qt6ct = { name = "Qt6 Settings"; noDisplay = true; };
    rofi = { name = "Rofi"; noDisplay = true; };
    "rofi-drun" = { name = "Rofi Drun"; noDisplay = true; };
    "rofi-theme-selector" = { name = "Rofi Theme Selector"; noDisplay = true; };
  };

  # Modular hyprland conf
  xdg.configFile."hypr/hyprland.conf" = {
    source = link "hyprland/hyprland.conf";
    force = true;
  };
  xdg.configFile."hypr/conf" = {
    source = link "hyprland/conf";
    force = true;
  };
  xdg.configFile."hypr/capture.sh" = {
    source = link "hyprland/capture.sh";
    force = true;
  };
  xdg.configFile."hypr/slideshow.sh" = {
    source = link "hyprland/slideshow.sh";
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
  xdg.configFile."wlogout/layout-other" = {
    source = link "wlogout/layout-other";
    force = true;
  };
  xdg.configFile."wlogout/style.css" = {
    source = link "wlogout/style.css";
    force = true;
  };
  xdg.configFile."wlogout/launch.sh" = {
    source = link "wlogout/launch.sh";
    force = true;
  };

  xdg.configFile."matugen" = {
    source = link "matugen";
    force = true;
  };

  # Dunst
  xdg.configFile."dunst/dunstrc" = {
    source = link "dunst/dunstrc";
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