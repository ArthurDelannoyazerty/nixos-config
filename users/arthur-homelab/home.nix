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

  # Safely check if Hyprland is even declared before checking if it's enabled.
  hyprlandAutoStart = if (osConfig.programs ? hyprland && osConfig.programs.hyprland.enable) then ''
    # Start Hyprland automatically if in TTY1
    if[ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland
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

    # CLI Tools (Migrated from shell.nix)
    btop
    tree
    nvitop
    bash-preexec
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

  /* -------------------------------------------------------------------------- */
  /*                                MISC CONFIGS                                */
  /* -------------------------------------------------------------------------- */

  # VSCode Link Overrides (If you ever SSH in and run a remote backend)
  xdg.configFile."Code/User/settings.json" = {
    source = link "codium/settings.json";
    force  = true;
  };
  xdg.configFile."Code/User/keybindings.json" = {
    source = link "codium/keybindings.json";
    force  = true;
  };

  # Starship
  xdg.configFile."starship.toml" = {
    source = link "starship/starship.toml";
    force = true;
  };

}