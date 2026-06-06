{ config, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.byparr.containerName}" = {
    image = "ghcr.io/thephaseless/byparr:${myConstants.services.byparr.version}";

    ports = [ (myConstants.bind myConstants.services.byparr.port) ];

    environment = {
      TZ = "Europe/Paris";
      LOG_LEVEL = "INFO";
    };

    # Headless browsers require extra shared memory to prevent crashing
    extraOptions = [
      "--shm-size=1gb"
    ];
  };
}