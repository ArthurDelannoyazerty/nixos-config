# /modules/home-manager/shell.nix
{ pkgs, dotfilesDir, dotfiles, osConfig, ... }:

let
  # Define the auto-start script conditionally.
  # It checks if 'programs.hyprland.enable' is set to true in the NixOS system config.
  hyprlandAutoStart = if osConfig.programs.hyprland.enable then ''
    # Start Hyprland automatically if in TTY1
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland
    fi
  '' else "";
in
{
  home.packages = with pkgs; [
    btop
    tree
    nvitop
    bash-preexec
  ];
  
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
}