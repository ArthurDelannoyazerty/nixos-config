{ pkgs, ... }:

{
  # Define the user in NixOS
  users.users.arthur = {
    isNormalUser = true;
    description = "Arthur Delannoy";
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "audio" ]; 
    shell = pkgs.bash;
  };

  # Import Home Manager for this user automatically
  home-manager.users.arthur = import ./home.nix;
}