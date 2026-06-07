{ config, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.komga.containerName}" = {
    image = "gotson/komga:${myConstants.services.komga.version}";

    ports = [ "${toString myConstants.services.komga.port}:25600" ];

    environmentFiles = [
      "${myConstants.paths.servicesSSD}/komga/secrets.env"
    ];

    environment = { 
      PUID = "1000"; 
      PGID = "1000"; 
      TZ = "Europe/Paris"; 
    };

    volumes = [
      # Komga config
      "${myConstants.paths.servicesSSD}/komga:/config"
      
      # Your manually added local manga
      "${myConstants.paths.disk4TB}/media/manga:/data"
      
      "${myConstants.paths.disk4TB}/services/suwayomi/downloads:/suwayomi-downloads"
      "${myConstants.paths.disk4TB}/services/tranga/downloads:/manga"
    ];
  };
}