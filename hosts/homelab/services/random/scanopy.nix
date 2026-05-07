{ config, pkgs, myConstants, ... }:

let
  envFile = "${myConstants.paths.servicesSSD}/scanopy/secrets.env";
  publicUrl = "https://${myConstants.services.scanopy.subdomain}.${myConstants.publicDomain}";
in
{
  virtualisation.oci-containers.containers = {
    
    ${myConstants.services.scanopy-daemon.containerName} = {
      image = "ghcr.io/scanopy/scanopy/daemon:${myConstants.services.scanopy-daemon.version}";
      environment = {
        SCANOPY_LOG_LEVEL = "info";
        SCANOPY_SERVER_URL = "http://127.0.0.1:${toString myConstants.services.scanopy.port}";
      };
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        "${myConstants.paths.servicesSSD}/scanopy/daemon:/root/.config/scanopy/daemon"
      ];
      extraOptions = [
        "--network=host"
        "--privileged"
      ];
    };

    ${myConstants.services.scanopy-db.containerName} = {
      image = "postgres:${myConstants.services.scanopy-db.version}";
      environment = {
        POSTGRES_DB = "scanopy";
        POSTGRES_USER = "postgres";
      };
      environmentFiles = [ envFile ]; # Expects POSTGRES_PASSWORD
      volumes = [ "${myConstants.paths.servicesSSD}/scanopy/postgres:/var/lib/postgresql/data" ];
    };

    ${myConstants.services.scanopy.containerName} = {
      image = "ghcr.io/scanopy/scanopy/server:${myConstants.services.scanopy.version}";
      dependsOn = [ 
        myConstants.services.scanopy-db.containerName 
        myConstants.services.scanopy-daemon.containerName
      ];
      ports = [ (myConstants.bind myConstants.services.scanopy.port) ];
      environment = {
        SCANOPY_LOG_LEVEL = "info";
        SCANOPY_WEB_EXTERNAL_PATH = "/app/static";
        SCANOPY_PUBLIC_URL = publicUrl;
        SCANOPY_INTEGRATED_DAEMON_URL = "http://host.docker.internal:60073";
     };
      environmentFiles = [ envFile ]; # Expects SCANOPY_DATABASE_URL
      volumes = [ "${myConstants.paths.servicesSSD}/scanopy/data:/data" ];
      extraOptions = [ 
        "--add-host=host.docker.internal:host-gateway"
        "--link=${myConstants.services.scanopy-db.containerName}:${myConstants.services.scanopy-db.containerName}" 
      ];
    };
  };
}