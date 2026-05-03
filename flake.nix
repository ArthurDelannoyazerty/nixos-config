{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles = {
      url = "github:ArthurDelannoyazerty/dotfiles";
      flake = false;    # That repo doesn't have a flake.nix
    };

    local-finance = {
      url = "github:ArthurDelannoyazerty/local-finance";
      flake = false;
    };
    
    grub2-themes.url = "github:vinceliuice/grub2-themes";

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
      localDotfilesExists = 
        let 
          exists = builtins.pathExists localDotfilesPath;
        in 
          builtins.trace "Checking for local dotfiles at ${localDotfilesPath}: ${if exists then "FOUND" else "NOT FOUND"}" exists;

      # Choose the source based on the check (github or local)
      dotfilesSrc = if localDotfilesExists
        then (builtins.path { path = localDotfilesPath; name = "dotfiles-local"; })
        else inputs.dotfiles;
      
      myConstants = import ./hosts/homelab/constants.nix;

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
          specialArgs = { 
            inherit inputs home-manager nix-vscode-extensions; 
            dotfiles = inputs.dotfiles;
            dotfilesDir = "/home/arthur/dotfiles";
            isLocal = true;
          };
          modules = [ 
            ./hosts/perso/configuration.nix
            {
              nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
            }
            inputs.grub2-themes.nixosModules.default
          ];
        };

        
        "homelab" = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
          specialArgs = { 
            inherit inputs home-manager nix-vscode-extensions myConstants; 
            dotfiles = inputs.dotfiles;               # Immutable GitHub repo
            dotfilesDir = "/home/arthur/dotfiles"; 
            isLocal = true;
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