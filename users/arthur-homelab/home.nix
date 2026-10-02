{pkgs, config, inputs, dotfilesDir, isLocal, osConfig, ...}:

let
  /* --------------------------------- Helpers -------------------------------- */
  link = path:
    if isLocal then
      config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}"
    else
      "${inputs.dotfiles}/${path}";

  hyprlandAutoStart =
    if (osConfig.programs ? hyprland && osConfig.programs.hyprland.enable) then ''
      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland
      fi
    ''
    else
      "";

in

{
  /* ------------------------------ Home Manager ------------------------------ */
  programs.home-manager.enable = true;

  home = {
    username = "arthur";
    homeDirectory = "/home/arthur";
    stateVersion = "25.05";

    packages = with pkgs; [
      # Fonts
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term

      bash-preexec

      # Media
      ffmpeg
      chromaprint
    ];
  };

  /* -------------------------------- Terminal -------------------------------- */
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


  /* -------------------------------- Dotfiles -------------------------------- */
  xdg.configFile = {
    # Starship
    "starship.toml" = {
      source = link "starship/starship.toml";
      force = true;
    };
  };
}