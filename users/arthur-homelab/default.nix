{ pkgs, ... }:

{
  # Define the user in NixOS
  users.users.arthur = {
    isNormalUser = true;
    # description = "Arthur Delannoy";
    extraGroups = [ "wheel" "networkmanager" "docker" ]; 
    shell = pkgs.bash;
    
    openssh.authorizedKeys.keyFiles = [
      (builtins.fetchurl "https://github.com/ArthurDelannoyazerty.keys")
    ];
  };

  # Import Home Manager for this user automatically
  home-manager.users.arthur = import ./home.nix;
}