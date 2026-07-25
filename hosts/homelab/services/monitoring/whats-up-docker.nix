{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.whats-up-docker.containerName} = {
    image = "getwud/wud:${myConstants.services.whats-up-docker.version}";
    
    # Internal Docker port is 3000, mapped to our constant port strictly on the docker bridge
    ports = [ "172.17.0.1:${toString myConstants.services.whats-up-docker.port}:3000" ];
    
    environment = {
      # Use the docker socket proxy instead of /var/run/docker.sock
      WUD_WATCHER_LOCAL_HOST = myConstants.dockerSocketProxy;
      WUD_WATCHER_LOCAL_PORT = "2375";
      
      # Also set standard DOCKER_HOST as fallback for standard Docker integrations
      DOCKER_HOST = "tcp://${myConstants.dockerSocketProxy}:2375";
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

