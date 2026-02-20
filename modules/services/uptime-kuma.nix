{ config, pkgs, myConstants, ... }:

{
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = toString myConstants.services.uptime-kuma.port;
      HOST = "127.0.0.1";
    };
  };
}