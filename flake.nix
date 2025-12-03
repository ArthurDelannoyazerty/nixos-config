{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles = {
      url = "github:ArthurDelannoyazerty/dotfiles";
      flake = false;    # That repo doesn't have a flake.nix
    };
    
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = { self, nixpkgs, home-manager, nix-vscode-extensions, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ nix-vscode-extensions.overlays.default ];
      };

      # --- Smart Dotfiles Logic ---
      localDotfilesPath = "/home/arthur/dotfiles";
      localDotfilesExists = builtins.pathExists localDotfilesPath;    # Check if that directory exists

      # Choose the source based on the check (github or local)
      dotfilesSrc = if localDotfilesExists
        then (builtins.path { path = localDotfilesPath; name = "dotfiles-local"; })
        else inputs.dotfiles;

    in {
      # Devcontainer
      packages.${system} = {
        devcontainer = import ./hosts/devcontainer/default.nix { 
          inherit pkgs;
          dotfilesInput = inputs.dotfiles; 
        };
      };

      nixosConfigurations = {
        "perso" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          # Pass our dynamically chosen `dotfilesSrc` to all modules as `dotfiles`.
          specialArgs = { 
            inherit inputs home-manager nix-vscode-extensions; 
            dotfiles = dotfilesSrc;
            dotfilesDir = localDotfilesPath;
            isLocal = localDotfilesExists;
          };
          modules = [ 
            ./hosts/perso/configuration.nix
            {
              nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
            }
          ];
        };

        
        "homelab" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { 
            inherit inputs home-manager nix-vscode-extensions; 
            dotfiles = dotfilesSrc;
            dotfilesDir = localDotfilesPath;
            isLocal = localDotfilesExists;
          };
          modules = [ 
            ./hosts/homelab/configuration.nix
            {
              nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
            }
          ];
        };
      };
    };
}