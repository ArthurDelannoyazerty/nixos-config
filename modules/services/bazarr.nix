{ config, pkgs, myConstants, ... }:

{
  services.bazarr = { 
    enable = true; 
    listenPort = myConstants.services.bazarr.port;
  };
}