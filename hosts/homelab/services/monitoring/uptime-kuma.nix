{ config, pkgs, myConstants, ... }:

{
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = toString myConstants.services.uptime-kuma.port;
      HOST = "0.0.0.0"; # Allow Docker containers to reach this
    };
  };
}