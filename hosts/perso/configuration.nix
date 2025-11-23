{ pkgs, home-manager, ... }:

{
  # Basic system settings
  system.stateVersion = "25.05"; 
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking.hostName = "nixos-perso";
  time.timeZone = "Europe/Paris";

  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "fr";
  services.xserver.layout = "fr";
  services.xserver.xkbVariant = ""; 

  services.displayManager.sddm.enable = false;

  services.getty.autologinUser = "arthur";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Define a user account
  users.users.arthur = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # sudo access
    shell = pkgs.bash;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable RealtimeKit (needed for audio scheduling priority)
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # Enables pulseaudio compatibility (vital for most apps)
    jack.enable = true;  # For music production tools
  };

  # List packages you want to install system-wide.
  environment.systemPackages = with pkgs; [
    git
    firefox
    vim
    curl
    wget
  ];

  # REUSABLE MODULES
  imports = [
    home-manager.nixosModules.home-manager

    ../../modules/home-manager
    ../../modules/hyprland
    ../../modules/terminal
    ../../modules/gaming
    ../../modules/dev
  ];
}