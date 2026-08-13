{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.local-finance = {
    # Pulling the exact image tag you provided from GHCR
    image = "ghcr.io/arthurdelannoyazerty/local-finance:${myConstants.services.finance.version}";
    
    # We map your custom host port (8501) to the container's internal port (8501)
    ports = [ "0.0.0.0:${toString myConstants.services.finance.port}:8000" ];
    
    environment = {
      TZ = "Europe/Paris";
    };

    volumes = [
      # Map the persistent storage on your fast SSD tier directly into the app
      "${myConstants.paths.servicesSSD}/local-finance/data:/data:rw"
    ];
    
    user = "1000:1000"; 
  };

  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/local-finance/data 0755 1000 1000 -"
  ];
}