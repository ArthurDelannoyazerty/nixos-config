{ config, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.radarr.containerName}" = {
    image = "lscr.io/linuxserver/radarr:${myConstants.services.radarr.version}";

    ports = [ (myConstants.bind myConstants.services.radarr.port) ];

    environment = { 
      PUID = "1000"; 
      PGID = "1000"; 
      TZ = "Europe/Paris"; 
    };
    
    volumes = [
      "${myConstants.paths.servicesSSD}/radarr:/config"
      # Drive where qBittorrent downloads
      "${myConstants.paths.services2TB}/qbittorrent/downloads:/downloads"
      # Drive where Jellyfin reads media
      "${myConstants.paths.disk4TB}/media:/media" 
    ];
  };
}