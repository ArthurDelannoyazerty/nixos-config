# /modules/services/vikunja/vikunja.nix
{ config, pkgs, myConstants, ... }:

{

  # Container Configuration
  virtualisation.oci-containers.containers.${myConstants.services.vikunja.containerName} = {
    image = "vikunja/vikunja:${myConstants.services.vikunja.version}";
    ports = [ (myConstants.bind myConstants.services.vikunja.port) ];

    environmentFiles = [
      "${myConstants.paths.servicesSSD}/vikunja/secret.env"
    ];
    
    environment = {
      # The URL is required for the API to function correctly
      VIKUNJA_SERVICE_PUBLICURL = "https://${myConstants.services.vikunja.subdomain}.${myConstants.publicDomain}/";
      # Use SQLite for a simple single-container setup
      VIKUNJA_DATABASE_TYPE = "sqlite"; 
      VIKUNJA_DATABASE_PATH = "/app/vikunja/db/vikunja.db";
      HOME = "/app/vikunja";

      VIKUNJA_AUTH_LOCAL_ENABLED = "false";
      VIKUNJA_SERVICE_ENABLEREGISTRATION = "false";
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/vikunja/files:/app/vikunja/files"
      "${myConstants.paths.servicesSSD}/vikunja/db:/app/vikunja/db"
    ];
  };

  # 3. Ensure data directories exist on host
  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/vikunja/files 0755 1000 100 -"
    "d ${myConstants.paths.servicesSSD}/vikunja/db 0755 1000 100 -"
  ];
}