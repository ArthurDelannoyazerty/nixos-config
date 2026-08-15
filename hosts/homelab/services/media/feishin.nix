{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.feishin.containerName} = {
    image = "ghcr.io/jeffvli/feishin:${myConstants.services.feishin.version}";
    
    ports = [ (myConstants.bind myConstants.services.feishin.port) ];

    environment = {
      SERVER_NAME = "Navidrome";
      SERVER_TYPE = "navidrome";
      SERVER_URL = "https://${myConstants.services.navidrome.subdomain}.${myConstants.publicDomain}";
      SERVER_LOCK = "false";
      PUID = "1000";
      PGID = "1000";
    };

    extraOptions = [ 
      "--add-host=host.docker.internal:host-gateway" 
    ];
  };
}