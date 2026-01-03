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
  ];


  # VSCode
  xdg.configFile."Code/User/settings.json" = {
    source = link "codium/settings.json";
    force  = true;
  };
  xdg.configFile."Code/User/keybindings.json" = {
    source = link "codium/keybindings.json";
    force  = true;
  };

}