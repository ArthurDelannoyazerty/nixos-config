{ config, pkgs, myConstants, ... }:

{
  # Ensure the config directory exists and is owned by UID 1000
  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/seerr 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers."${myConstants.services.seerr.containerName}" = {
    image = "ghcr.io/seerr-team/seerr:${myConstants.services.seerr.version}";
    
    ports = [ 
      (myConstants.bind myConstants.services.seerr.port) 
    ];

    environment = {
      TZ = "Europe/Paris";
      PORT = toString myConstants.services.seerr.port;
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/seerr:/app/config"
    ];
  };
}