{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.ariang.containerName} = {
    image = "hurlenko/aria2-ariang:${myConstants.services.ariang.version}";
    
    ports = [ 
      "0.0.0.0:${toString myConstants.services.ariang.port}:8080"      # Web UI
      "0.0.0.0:${toString myConstants.services.ariang.rpc-port}:6800" # RPC Endpoint
    ];
    
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "Europe/Paris";
    };

    environmentFiles = [
      # Create this file and add: ARIA2_RPC_SECRET=your_strong_secret_password
      "${myConstants.paths.servicesSSD}/ariang/secrets.env"
    ];

    volumes = [
      "${myConstants.paths.servicesSSD}/ariang/config:/aria2/conf:rw"
      "${myConstants.paths.disk4TB}/downloads:/aria2/data:rw"
    ];
  };
}