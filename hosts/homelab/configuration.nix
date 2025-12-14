{ pkgs, home-manager, inputs, dotfiles, dotfilesDir, isLocal, nix-vscode-extensions, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager    
    
    # hardware
    ./hardware-configuration.nix

    # modules
    ../../modules/nixos/base.nix
    ../../modules/terminal
    ../../modules/dev
    ../../modules/nixos/server.nix

    # users
    ../../users/arthur-homelab/default.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs dotfiles dotfilesDir isLocal nix-vscode-extensions;
    };
  };

  # Basic system settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = false;

  networking.hostName = "nixos-homelab";
  networking.networkmanager.enable = true; 

  console.keyMap = "fr";

  # Do not sleep when the lid is closed
  services.logind.settings.Login = {
    lidSwitch = "ignore";
    lidSwitchDocked = "ignore";
    lidSwitchExternalPower = "ignore";
  };
  
  # Optional: Prevent the system from sleeping automatically due to inactivity
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

}