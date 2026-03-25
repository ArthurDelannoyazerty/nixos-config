# /modules/services/vikunja/vikunja.nix
{ config, pkgs, myConstants, ... }:

{

  # Container Configuration
  virtualisation.oci-containers.containers.${myConstants.services.vikunja.containerName} = {
    image = "vikunja/vikunja:${myConstants.services.vikunja.version}";
    ports = [ (myConstants.bind myConstants.services.vikunja.port) ];

    environmentFiles = [
      "/var/lib/vikunja/secret.env"
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
      # Persist data on the host
      "/var/lib/vikunja/files:/app/vikunja/files"
      "/var/lib/vikunja/db:/app/vikunja/db"
    ];
  };

  # 3. Ensure data directories exist on host
  systemd.tmpfiles.rules = [
    "d /var/lib/vikunja/files 0755 1000 100 -"
    "d /var/lib/vikunja/db 0755 1000 100 -"
  ];
}