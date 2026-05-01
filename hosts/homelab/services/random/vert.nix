{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.vert.containerName} = {
    image = "ghcr.io/vert-sh/vert:${myConstants.services.vert.version}";
    
    ports =[ "127.0.0.1:${toString myConstants.services.vert.port}:80" ];
    
    environment = {
      PUB_ENV = "production";
      PUB_HOSTNAME = "${myConstants.services.vert.subdomain}.${myConstants.publicDomain}";
      PUB_VERTD_URL = "https://${myConstants.services.vertd.subdomain}.${myConstants.publicDomain}";
    };
  };
}