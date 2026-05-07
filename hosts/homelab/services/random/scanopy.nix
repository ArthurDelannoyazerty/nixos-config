{ config, pkgs, myConstants, ... }:

let
  envFile = "${myConstants.paths.servicesSSD}/scanopy/secrets.env";
  
  commonEnv = {
    DB_HOST = myConstants.services.scanopy-db.containerName;
    DB_PORT = "5432";
    DB_NAME = "scanopy";
    DB_USER = "scanopy";
    REDIS_HOST = myConstants.services.scanopy-redis.containerName;
    REDIS_PORT = "6379";
  };
in
{
  virtualisation.oci-containers.containers = {
    
    # Database
    ${myConstants.services.scanopy-db.containerName} = {
      image = "postgres:${myConstants.services.scanopy-db.version}";
      environment = {
        POSTGRES_DB = "scanopy";
        POSTGRES_USER = "scanopy";
      };
      environmentFiles = [ envFile ]; # Expects POSTGRES_PASSWORD
      volumes = [ "${myConstants.paths.servicesSSD}/scanopy/postgres:/var/lib/postgresql/data" ];
    };

    # Redis
    ${myConstants.services.scanopy-redis.containerName} = {
      image = "redis:${myConstants.services.scanopy-redis.version}";
    };

    # Backend Server
    ${myConstants.services.scanopy-server.containerName} = {
      image = "scanopy/scanopy-server:${myConstants.services.scanopy-server.version}";
      dependsOn = [ myConstants.services.scanopy-db.containerName myConstants.services.scanopy-redis.containerName ];
      environment = commonEnv;
      environmentFiles = [ envFile ]; # Expects DB_PASSWORD
      extraOptions = [ 
        "--link=${myConstants.services.scanopy-db.containerName}" 
        "--link=${myConstants.services.scanopy-redis.containerName}" 
      ];
    };

    # Frontend UI
    ${myConstants.services.scanopy.containerName} = {
      image = "scanopy/scanopy-ui:${myConstants.services.scanopy.version}";
      ports = [ (myConstants.bind myConstants.services.scanopy.port) ];
      environment = {
        SCANOPY_API_URL = "https://${myConstants.services.scanopy.subdomain}.${myConstants.publicDomain}/api";
      };
    };
  };
}