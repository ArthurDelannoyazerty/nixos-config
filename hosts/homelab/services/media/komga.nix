{ config, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${services.komga.containerName}" = {
    image = "gotson/komga:${services.komga.version}";

    ports = [ (myConstants.bind services.komga.port) ];

    environment = { 
      PUID = "1000"; 
      PGID = "1000"; 
      TZ = "Europe/Paris"; 
    };

    volumes = [
      "${paths.servicesSSD}/komga:/config"
      "${paths.disk4TB}/media/manga:/data"
    ];
  };
}