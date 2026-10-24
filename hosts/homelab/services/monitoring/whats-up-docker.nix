{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.whats-up-docker.containerName} = {
    image = "getwud/wud:${myConstants.services.whats-up-docker.version}";
    
    # Internal Docker port is 3000, mapped to our constant port strictly on the docker bridge
    ports = [ "172.17.0.1:${toString myConstants.services.whats-up-docker.port}:3000" ];
    
    # Load bootstrap admin credentials
    environmentFiles = [
      "${myConstants.paths.servicesSSD}/whats-up-docker/secrets.env"
    ];

    environment = {
      WUD_WATCHER_LOCAL_HOST = "socket-proxy";
      WUD_WATCHER_LOCAL_PORT = "2375";
      
      # Standard DOCKER_HOST fallback
      DOCKER_HOST = "tcp://${myConstants.dockerSocketProxy}:2375";

      WUD_WATCHER_LOCAL_WATCHDIGEST = "true";
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/whats-up-docker/store:/store"
    ];

    extraOptions = [ 
      "--add-host=host.docker.internal:host-gateway" 
      "--link=socket-proxy:socket-proxy"
    ];
  };
}