{ config, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.sonarr.containerName}" = {
    image = "lscr.io/linuxserver/sonarr:${myConstants.services.sonarr.version}";

    ports = [ (myConstants.bind myConstants.services.sonarr.port) ];

    environment = { 
      PUID = "1000"; 
      PGID = "1000"; 
      TZ = "Europe/Paris"; 
    };
    
    volumes = [
      "${myConstants.paths.servicesSSD}/sonarr:/config"
      # Drive where qBittorrent downloads
      "${myConstants.paths.services2TB}/qbittorrent/downloads:/downloads"
      # Drive where Jellyfin reads media
      "${myConstants.paths.disk4TB}/media:/media" 
    ];
  };
}