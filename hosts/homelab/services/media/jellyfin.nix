{ config, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.jellyfin.containerName}" = {
    image = "lscr.io/linuxserver/jellyfin:${myConstants.services.jellyfin.version}";

    ports = [ (myConstants.bind myConstants.services.jellyfin.port) ];

    environment = { 
      PUID = "1000"; 
      PGID = "1000"; 
      TZ = "Europe/Paris"; 
    };

    volumes = [
      "${paths.servicesSSD}/jellyfin:/config"
      "${paths.disk4TB}/media:/data"
    ];
  };
}