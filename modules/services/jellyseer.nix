{ config, pkgs, myConstants, ... }:

{
  services.jellyseerr = { 
    enable = true; 
    port = myConstants.services.jellyseerr.port; 
  };
}