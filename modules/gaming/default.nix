# /modules/gaming/default.nix

{ pkgs, config, ... }:

{
  # Graphics drivers
  hardware.graphics = {
      enable = true;
      enable32Bit = true;
  };

  # Gaming softwares
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