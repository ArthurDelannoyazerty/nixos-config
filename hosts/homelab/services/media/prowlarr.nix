{ config, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.prowlarr.containerName}" = {
    image = "lscr.io/linuxserver/prowlarr:${myConstants.services.prowlarr.version}";

    ports = [ (myConstants.bind myConstants.services.prowlarr.port) ];

    environment = { 
      PUID = "1000"; 
      PGID = "1000"; 
      TZ = "Europe/Paris"; 
    };
    volumes = [ "${myConstants.paths.servicesSSD}/prowlarr:/config" ];
  };
}