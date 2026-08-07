{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.obsidian2docmost.containerName} = {
    image = "obsidian2docmost:${myConstants.services.obsidian2docmost.version}"; 
    
    # Map the host port (8502) to the container's hardcoded port (8080)
    ports = [ "0.0.0.0:${toString myConstants.services.obsidian2docmost.port}:8080" ];
    

  };
}