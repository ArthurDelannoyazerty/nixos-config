# PLACEHOLDER !! PLACEHOLDER !! PLACEHOLDER !! PLACEHOLDER !!
# PLACEHOLDER !! PLACEHOLDER !! PLACEHOLDER !! PLACEHOLDER !!
# PLACEHOLDER !! PLACEHOLDER !! PLACEHOLDER !! PLACEHOLDER !!
# PLACEHOLDER !! PLACEHOLDER !! PLACEHOLDER !! PLACEHOLDER !!

# This is a function that accepts the final package set (self) and the original (super)
# It returns a set of modifications.
self: super: {

  # We want to modify the 'btop' package
  btop = super.btop.overrideAttrs (oldAttrs: {
    # 'overrideAttrs' lets us change attributes of the existing package definition.
    # We only want to change its version and source code.
    version = "1.2.13";
    
    src = super.fetchFromGitHub {
      owner = "aristocratos";
      repo = "btop";
      # This is the specific commit/tag we want
      rev = "d21114b76a6b86a76e27bde4228965f7c35a8157";
      # The hash is required for reproducibility and security.
      # Nix will compute this for you if you get it wrong.
      hash = "sha256-kC9+cfl3JmC9eT+n0Iu3Gflc/E34iBwzBWH6y2o2t3k=";
    };
  });

}



# ------------------------------------------------------------------------

# Then the ./flake.nix should also use that file like following : 


# outputs = { self, nixpkgs, ... }@inputs:
#   let
#     # This is a helper that applies our overlays to the nixpkgs package set.
#     pkgsFor = system: import nixpkgs {
#       inherit system;
#       # This is the key line!
#       config.overlays = [ self.overlays.default ];
#     };
#   in
# {
#   # Define your custom overlay as an output so it can be referenced above.
#   overlays.default = import ./overlays/default.nix;

#   # =========================================================================
#   # == NIXOS CONFIGURATIONS
#   # =========================================================================
#   nixosConfigurations = {
#     "personal-desktop" = nixpkgs.lib.nixosSystem {
#       system = "x86_64-linux";
#       specialArgs = { inherit inputs; };
#       modules = [
#         # Here we pass the MODIFIED package set to our host configuration.
#         ({ config, pkgs, ... }: {
#           nixpkgs.pkgs = pkgsFor "x86_64-linux";
#         })
#         ./hosts/personal-desktop
#       ];
#     };

#     "homelab-server" = nixpkgs.lib.nixosSystem {
#       system = "x86_64-linux";
#       specialArgs = { inherit inputs; };
#       modules = [
#         ({ config, pkgs, ... }: {
#           nixpkgs.pkgs = pkgsFor "x86_64-linux";
#         })
#         ./hosts/homelab-server
#       ];
#     };
#   };
# };