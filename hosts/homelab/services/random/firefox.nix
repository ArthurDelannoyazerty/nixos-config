{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.firefox.containerName} = {
    image = "lscr.io/linuxserver/firefox:${myConstants.services.firefox.version}";
    
    # We map your custom host port to the container's internal HTTP port (3000)
    ports = [ "0.0.0.0:${toString myConstants.services.firefox.port}:3000" ];
    
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "Europe/Paris";
      # NOTE: We DO NOT set CUSTOM_USER or PASSWORD here. 
      # Since we are protecting it with Authentik via Caddy, we can leave the internal app unauthenticated.
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/firefox/config:/config:rw"
      # This maps a 'downloads' folder on your 2TB HDD directly into Firefox
      "${myConstants.paths.disk4TB}/downloads:/downloads:rw"
    ];

    extraOptions = [ 
      # CRITICAL: Modern browsers crash in Docker without this because of sandbox restrictions
      "--security-opt=seccomp=unconfined"
      # CRITICAL: Gives the container 1GB of shared memory to prevent tab crashes on heavy sites
      "--shm-size=1gb"
    ];
  };
}