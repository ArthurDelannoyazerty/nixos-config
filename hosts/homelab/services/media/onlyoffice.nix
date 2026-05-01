{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.onlyoffice.containerName}" = {
    image = "onlyoffice/documentserver:latest";
    
    environmentFiles =[
      "${myConstants.paths.servicesSSD}/onlyoffice/secrets.env"
    ];

    ports =[
      "0.0.0.0:${toString myConstants.services.onlyoffice.port}:80"
    ];
  };
}