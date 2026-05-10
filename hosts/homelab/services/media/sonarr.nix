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
      "${paths.servicesSSD}/sonarr:/config"
      "${paths.disk4TB}/media/anime:/anime" # Final library
      "${paths.disk2TB}/downloads:/downloads" # Access to qbit downloads
    ];
  };
}