{ pkgs, inputs, ... }:

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
  ];

  # --- BASH CONFIGURATION ---
  programs.bash = {
    enable = true;
    # This is the cleanest way to use your custom bashrc. It gets sourced
    # after the standard NixOS bash setup.
    initExtra = ''
      # Source the .bashrc from the dotfiles repository
      if [ -f "${inputs.dotfiles}/bash/.bashrc" ]; then
        source "${inputs.dotfiles}/bash/.bashrc"
      fi
    '';
  };

  # --- PURELINE CONFIGURATION ---
  # This declaratively links the files from your dotfiles repo to the
  # correct location in your home directory.
  home.file.".pureline.job.conf".source = "${inputs.dotfiles}/pureline/.pureline.job.conf";
  home.file.".pureline.personal.conf".source = "${inputs.dotfiles}/pureline/.pureline.personal.conf";
}