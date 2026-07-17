{ pkgs, ... }:

{
  # Basic system settings
  system.stateVersion = "25.05";
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  # Documentation DAG Nix config
  imports = [
    ./architecture-dag.nix
  ];

  # Enable networking
  networking.networkmanager.enable = true;

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # run dynamically linked binaries 
  programs.nix-ld.enable = true;

  programs.nh = {
    enable = true;
    flake = "/home/arthur/nixos-config";
  };

  # Install common system-wide packages
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    vim
    curl
    wget
    unixtools.ping
    openssl
    openssh
    lshw
    util-linux
    coreutils
    findutils
    gnutar
    gzip
    procps
    gnugrep
    which
    htop
    tldr
    dmidecode 
    lsof 
    unixtools.netstat
    hwinfo
    unzip
    unrar
    zip
    lm_sensors
    networkmanager
    iw
    iwd
    jq
  ];


  programs.coolercontrol.enable = true;

  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    nerd-fonts.iosevka
    nerd-fonts.iosevka-term
  ];

  # Add binary caches to speed up downloads
  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}