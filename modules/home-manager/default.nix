{ inputs, dotfiles, dotfilesDir, isLocal, ... }:

{
  # Enable and configure home-manager as a NixOS module
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Tell home-manager where to find the user configuration
    users.arthur = import ./home.nix;
    # Pass down special arguments (like inputs)
    extraSpecialArgs = { inherit inputs dotfiles dotfilesDir isLocal; };
  };
}