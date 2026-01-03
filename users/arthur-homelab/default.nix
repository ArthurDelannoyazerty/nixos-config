{ pkgs, ... }:

{
  # Define the user in NixOS
  users.users.arthur = {
    isNormalUser = true;
    # description = "Arthur Delannoy";
    extraGroups = [ "wheel" "networkmanager" "docker" ]; 
    shell = pkgs.bash;
    
    openssh.authorizedKeys.keyFiles = [
      (builtins.fetchurl {
        url = "https://github.com/ArthurDelannoyazerty.keys";
        sha256 = "015yna27qs3jgm4v0xgq5pr8kapad3b126f4309m4p712h6mr14w";
      })
    ];
  };

  # Import Home Manager for this user automatically
  home-manager.users.arthur = import ./home.nix;
}