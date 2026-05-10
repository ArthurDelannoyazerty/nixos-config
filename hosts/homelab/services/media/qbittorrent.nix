{ config, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.qbittorrent.containerName}" = {
    image = "lscr.io/linuxserver/qbittorrent:${myConstants.services.qbittorrent.version}";

    ports = [ (myConstants.bind myConstants.services.qbittorrent.port) "6881:6881" "6881:6881/udp" ];
    
    environment = {
      PUID = "1000"; 
      PGID = "1000";
      TZ = "Europe/Paris";
      WEBUI_PORT = toString myConstants.services.qbittorrent.port;
    };
    volumes = [
      "${paths.servicesSSD}/qbittorrent:/config"
      "${paths.disk2TB}/downloads:/downloads"
    ];
  };
}