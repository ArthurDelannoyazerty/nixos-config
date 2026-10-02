{pkgs, config, inputs, dotfilesDir, isLocal, osConfig, ...}:

let
  /* --------------------------------- Helpers -------------------------------- */
  link = path:
    if isLocal then
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}"
    else
      "${inputs.dotfiles}/${path}";

  # Auto-start if in TTY
  hyprlandAutoStart =
    if (osConfig.programs ? hyprland && osConfig.programs.hyprland.enable) then ''
      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec start-hyprland
      fi
    ''
    else
      "";


  /* ----------------------------- Custom packages ---------------------------- */
  aw-watcher-input = pkgs.python3Packages.buildPythonApplication rec {
    pname = "aw-watcher-input";
    version = "master";
    format = "pyproject";

    src = pkgs.fetchFromGitHub {
      owner = "ActivityWatch";
      repo = "aw-watcher-input";
      rev = "master";
      hash = "sha256-T7RIzrv+WzA5gEUlU/0dR1Fl0b8zH8q/q80WMBIosPM=";
    };

    nativeBuildInputs = [pkgs.python3Packages.poetry-core];

    propagatedBuildInputs = with pkgs.python3Packages; [
      aw-client
      pynput
    ] ++ [
      pkgs.aw-watcher-afk
    ];

    # aw-watcher-afk is provided explicitly above.
    postPatch = ''
      sed -i '/aw-watcher-afk/d' pyproject.toml
    '';

    dontCheckRuntimeDeps = true;
    doCheck = false;
  };

in

{
  /* ------------------------------ Home Manager ------------------------------ */
  programs.home-manager.enable = true;

  home = {
    username = "arthur";
    homeDirectory = "/home/arthur";
    stateVersion = "25.05";

    sessionVariables = {
      SSH_AUTH_SOCK = "/home/arthur/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock";
    };

    packages = with pkgs; [
      # Fonts
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term
      inter
      corefonts
      vista-fonts

      # Themes / desktop
      papirus-icon-theme
      reversal-icon-theme
      tela-circle-icon-theme
      adwaita-icon-theme

      # Desktop utilities
      brightnessctl
      swayosd
      baobab
      imagemagick
      rofi-network-manager
      rofi-pulse-select
      socat

      # Applications
      obsidian
      tailscale
      onlyoffice-desktopeditors
      kdePackages.kdenlive
      crosspipe
      motrix

      # CLI
      btop
      tree
      nvitop
      bash-preexec

      # Hyprland
      awww
      matugen

      # Game / launcher tools
      ludusavi
      rclone
      heroic
      faugus-launcher

      # Patched Cartridges
      (cartridges.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          substituteInPlace $out/lib/python*/site-packages/cartridges/window.py \
            --replace-fail "label=games_no," "label=str(games_no),"
        '';
      }))

      lumafly

      # Media
      ffmpeg
      chromaprint
      nodejs

      # Celeste mod manager
      (olympus.override {
        celesteWrapper = "steam-run";
      })
    ];
  };


  /* ---------------------------- Shell / terminal ---------------------------- */
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
      ${hyprlandAutoStart}

      if [ -f "${dotfilesDir}/bash/.bashrc" ]; then
        source "${dotfilesDir}/bash/.bashrc"
      elif [ -f "${inputs.dotfiles}/bash/.bashrc" ]; then
        source "${inputs.dotfiles}/bash/.bashrc"
      fi

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


  /* ------------------------------ Applications ------------------------------ */
  programs.mpv = {
    enable = true;

    config = {
      osc = false;
      osd-bar = false;
      border = false;
    };

    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
    ];

    scriptOpts = {
      thumbfast = {
        network = "yes";
        hwdec = "yes";
      };
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.unstable.vscode;
    mutableExtensionsDir = true;
  };


  /* --------------------------------- Desktop -------------------------------- */
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

    # Let GTK4 applications use native Libadwaita.
    gtk4.theme = null;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  dconf.settings = {
    "org/cinnamon/desktop/applications/terminal" = {
      exec = "kitty";
    };
  };


  /* -------------------------------- Services -------------------------------- */
  services.dunst.enable = true;
  services.swayosd.enable = true;
  services.easyeffects.enable = true;

  services.activitywatch = {
    enable = true;

    watchers = {
      # Wayland replacement for the standard window / AFK watchers.
      aw-awatcher = {
        package = pkgs.awatcher;
        executable = "awatcher";
      };

      aw-watcher-input = {
        package = aw-watcher-input;
        executable = "aw-watcher-input";
      };
    };
  };

  
  /* ----------------------- Automated game save backups ---------------------- */
  systemd.user.services.ludusavi-backup = {
    Unit = {
      Description = "Automated Ludusavi Game Save Backup";
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.ludusavi}/bin/ludusavi backup --force";
    };
  };

  systemd.user.timers.ludusavi-backup = {
    Unit = {
      Description = "Timer for Automated Ludusavi Game Save Backup";
    };

    Timer = {
      OnCalendar = "daily";
      Persistent = true;
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  
  /* --------------------------------- Polkit --------------------------------- */
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit.Description = "polkit-gnome-authentication-agent-1";

    Install.WantedBy = [
      "graphical-session.target"
    ];

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  /* ----------------------------------- XDG ---------------------------------- */
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "inode/directory" = [ "nemo.desktop" ];
      "application/x-gnome-saved-search" = [ "nemo.desktop" ];
    };
  };

    # Hide rofi menu items
  xdg.desktopEntries = {
    htop = {name = "htop";noDisplay = true;};
    btop = {name = "btop";noDisplay = true;};
    nvtop = {name = "nvtop";noDisplay = true;};
    kvantummanager = {name = "Kvantum Manager";noDisplay = true;};
    "nixos-manual" = {name = "NixOS Manual";noDisplay = true;};
    qt5ct = {name = "Qt5 Settings";noDisplay = true;};
    qt6ct = {name = "Qt6 Settings";noDisplay = true;};
    rofi = {name = "Rofi";exec = "rofi";noDisplay = true;};
    "rofi-theme-selector" = {name = "Rofi Theme Selector";exec = "rofi-theme-selector";noDisplay = true;};
    activitywatch = {
      name = "ActivityWatch";
      genericName = "Time Tracker";
      exec = "xdg-open http://localhost:5600";
      icon = "preferences-system-time";
      comment = "View your ActivityWatch statistics";
      categories = [ "Utility" ];
    };
  };

  /* -------------------------------- Dotfiles -------------------------------- */
  xdg.configFile = {
    # Shell
    "starship.toml" = {
      source = link "starship/starship.toml";
      force = true;
    };

    "kitty/kitty.conf" = {
      source = link "kitty/kitty.conf";
      force = true;
    };

    # Hyprland
    "hypr/hyprland.conf" = {
      source = link "hyprland/hyprland.conf";
      force = true;
    };

    "hypr/conf" = {
      source = link "hyprland/conf";
      force = true;
    };

    "hypr/capture.sh" = {
      source = link "hyprland/capture.sh";
      force = true;
    };

    "hypr/slideshow.sh" = {
      source = link "hyprland/slideshow.sh";
      force = true;
    };

    "hypr/layout_osd.sh" = {
      source = link "hyprland/layout_osd.sh";
      force = true;
    };

    "hypr/hyprlock.conf" = {
      source = link "hyprlock/hyprlock.conf";
      force = true;
    };

    # Rofi
    "rofi/" = {
      source = link "rofi/";
      force = true;
    };

    # Waybar
    "waybar/config.jsonc" = {
      source = link "waybar/config.jsonc";
      force = true;
    };

    "waybar/style.css" = {
      source = link "waybar/style.css";
      force = true;
    };

    # Wlogout
    "wlogout/layout" = {
      source = link "wlogout/layout";
      force = true;
    };

    "wlogout/layout-other" = {
      source = link "wlogout/layout-other";
      force = true;
    };

    "wlogout/style.css" = {
      source = link "wlogout/style.css";
      force = true;
    };

    "wlogout/launch.sh" = {
      source = link "wlogout/launch.sh";
      force = true;
    };

    # Matugen
    "matugen" = {
      source = link "matugen";
      force = true;
    };

    # Notifications
    "dunst/dunstrc" = {
      source = link "dunst/dunstrc";
      force = true;
    };

    # SwayOSD
    "swayosd/style.css" = {
      source = link "swayosd/style.css";
      force = true;
    };

    "swayosd/config.toml" = {
      source = link "swayosd/config.toml";
      force = true;
    };
  };
}