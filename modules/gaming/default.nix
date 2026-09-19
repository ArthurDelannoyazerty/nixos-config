# /modules/gaming/default.nix

{ pkgs, config, ... }:

{
  # =========================================================================
  # == GRAPHICS DRIVERS & 32-BIT SUPPORT
  #    Essential for running most games via Steam/Proton.
  # =========================================================================

  hardware.graphics = {
      enable = true;
      enable32Bit = true;
  };

  # =========================================================================
  # == GAMING SOFTWARE & SERVICES
  # =========================================================================

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; 
    dedicatedServer.openFirewall = true; 
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud    
    gamescope   
  ];

  # Xbox controller 
  hardware.xpadneo.enable = true;
  hardware.steam-hardware.enable = true;
}