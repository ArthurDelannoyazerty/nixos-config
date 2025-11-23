{ inputs, dotfiles, dotfilesDir, isLocal, nix-vscode-extensions, ... }:

{
  # Enable and configure home-manager as a NixOS module
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Backup any existing config nixos doesn't own
    backupFileExtension = "backup";
    # Tell home-manager where to find the user configuration
    users.arthur = import ./home.nix;
    # Pass down special arguments (like inputs)
    extraSpecialArgs = { inherit inputs dotfiles dotfilesDir isLocal nix-vscode-extensions; };
  };
}