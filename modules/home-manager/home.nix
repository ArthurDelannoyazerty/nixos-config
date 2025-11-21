{ pkgs, config, inputs, dotfiles, dotfilesDir, isLocal, ... }:




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

in

{
  # Let Home Manager manage itself
  programs.home-manager.enable = true;
  # This needs to be set for Home Manager to work correctly
  home.stateVersion = "23.11";

  # Set your home directory and username
  home.username = "arthur";
  home.homeDirectory = "/home/arthur";

  # Packages to install in your user profile
  home.packages = with pkgs; [
    btop
    tree
    nvitop
    bash-preexec
    
    # Fonts
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
  ];

  # set the hyprland.conf to the right place
  # Note: We use the 'link' function and pass the path relative to the repo root
  xdg.configFile."hypr/hyprland.conf".source = link "hyprland/hyprland.conf";

  # --- BASH ---
  # Bash is special because it uses 'source' inside the file, not a symlink.
  # We can keep using ${dotfiles} here because we just want to read the file.
  # Or, if you edit .bashrc and want instant updates without 'nixos-rebuild',
  # you can point to the local path too:
  programs.bash = {
    enable = true;
    initExtra = ''
      # Start Hyprland automatically if in TTY1
      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland
      fi

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

  programs.kitty = {
    enable = true;
    font = {
      name = "IosevkaTerm Nerd Font Mono";
      size = 12;
    };
    settings = {
      # Optional: Add window padding or transparency if you like
      window_padding_width = 4;
      confirm_os_window_close = 0;
    };
  };

  # --- PURELINE CONFIGURATION ---
  # This declaratively links the files from your dotfiles repo to the
  # correct location in your home directory.
  home.file.".pureline.job.conf".source      = link "pureline/.pureline.job.conf";
  home.file.".pureline.personal.conf".source = link "pureline/.pureline.personal.conf";


  # VSCODIUM
  xdg.configFile."VSCodium/User/settings.json".source = link "codium/settings.json";
  xdg.configFile."VSCodium/User/settings.json".force  = true;        # Force replacement of existing files
  xdg.configFile."VSCodium/User/keybindings.json".source = link "codium/keybindings.json";
  xdg.configFile."VSCodium/User/keybindings.json".force  = true;


  programs.atuin = {
    enable = true;
    enableBashIntegration = true; # This ensures the hooks are added to .bashrc
    settings = {
      # Disable all online sync features
      auto_sync = false;
      update_check = false;
      sync_address = "";
        
      # UI Settings
      style = "compact";
      inline_height = 10;    # Limits height to 10 lines (cleaner)
      show_preview = true;   # Shows context of the command
    };
  };


  # Waybar
  xdg.configFile."waybar/config.jsonc".source = link "waybar/config.jsonc";
  xdg.configFile."waybar/style.css".source = link "waybar/style.css";

}