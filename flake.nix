{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    grub2-themes.url = "github:vinceliuice/grub2-themes";

    dotfiles = {
      url = "github:ArthurDelannoyazerty/dotfiles";
      flake = false;
    };

    local-finance = {
      url = "github:ArthurDelannoyazerty/local-finance";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";

      /* ----------------------------- Global overlays ---------------------------- */
      unstableOverlay = _final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };

      commonOverlays = [
        inputs.nix-vscode-extensions.overlays.default
        unstableOverlay
      ];

      # Same package set used by standalone flake packages.
      pkgs = import nixpkgs {
        inherit system;

        config.allowUnfree = true;
        overlays = commonOverlays;
      };

      # Inject common overlays into every NixOS host.
      overlaysModule = {
        nixpkgs.overlays = commonOverlays;
      };

      /* ----------------------------------- Lix ---------------------------------- */
      lixModule = { pkgs, ... }: {
        nix.package = pkgs.lixPackageSets.stable.lix;

        nixpkgs.overlays = [
          (_final: prev: {
            inherit (prev.lixPackageSets.stable)
              nixpkgs-review
              nix-eval-jobs
              nix-fast-build
              colmena;
          })
        ];
      };
    in
    {
      /* ------------------------------ Devcontainer ------------------------------ */
      packages.${system} = {
        devcontainer = import ./hosts/devcontainer/default.nix {
          inherit pkgs;
          nixpkgsInput = inputs.nixpkgs;
          nixpkgsUnstableInput = inputs.nixpkgs-unstable;
        };

        devcontainer-stream = import ./hosts/devcontainer/default.nix {
          inherit pkgs;
          nixpkgsInput = inputs.nixpkgs;
          nixpkgsUnstableInput = inputs.nixpkgs-unstable;
          stream = true;
        };
      };
      
      /* ---------------------------------- Hosts --------------------------------- */
      nixosConfigurations = {
        /* ------------------------------- nixos-perso ------------------------------ */
        nixos-perso = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/perso/configuration.nix
            overlaysModule
            lixModule
            inputs.grub2-themes.nixosModules.default
            inputs.nix-flatpak.nixosModules.nix-flatpak
          ];
        };

        /* ----------------------------- nixos-portable ----------------------------- */
        nixos-portable = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/portable/configuration.nix
            overlaysModule
            lixModule
            inputs.grub2-themes.nixosModules.default
            inputs.nix-flatpak.nixosModules.nix-flatpak
          ];
        };

        /* ------------------------------ nixos-homelab ----------------------------- */
        nixos-homelab = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            myConstants = import ./hosts/homelab/constants.nix;
          };
          modules = [
            ./hosts/homelab/configuration.nix
            overlaysModule
            lixModule
          ];
        };
      };
    };
}