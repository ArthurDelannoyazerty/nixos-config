{ config, pkgs, myConstants, ... }:

let
  envFile = "/var/lib/authentik/secrets.env";

  # Common optimization settings to make Authentik fast on Homelabs
  commonEnv = {
    # 1. Disable the massive GeoIP download (Save RAM and CPU)
    AUTHENTIK_ERROR_REPORTING__ENABLED = "false";
    AUTHENTIK_DISABLE_STARTUP_ANALYTICS = "true";
    AUTHENTIK_AUTHENTIK__GEOIP = "/dev/null"; # This effectively disables GeoIP
    
    # 2. Redis/DB Connection info
    AUTHENTIK_REDIS__HOST = myConstants.services.authentik-redis.containerName;
    AUTHENTIK_POSTGRESQL__HOST = myConstants.services.authentik-db.containerName;
    AUTHENTIK_POSTGRESQL__USER = "authentik";
    AUTHENTIK_POSTGRESQL__NAME = "authentik";

    
    AUTHENTIK_WEB__WORKERS = "1";         # Only run 1 server process (Default is based on CPU cores)
    AUTHENTIK_WORKER__CONCURRENCY = "1";  # Only run 1 background worker
    AUTHENTIK_WEB__THREADS = "2";         # Reduce threads per worker
  };
in
{
  # Virtual user for secrets owning
  users.groups.authentik = { gid = 1000; };
  users.users.authentik = {
    isSystemUser = true;
    group = "authentik";
  };

  virtualisation.oci-containers.containers = {
    # Server
    ${myConstants.services.authentik.containerName} = {
      image = "ghcr.io/goauthentik/server:${myConstants.services.authentik.version}";
      dependsOn = [ 
        (toString myConstants.services.authentik-db.containerName) 
        (toString myConstants.services.authentik-redis.containerName) 
      ];
      cmd = [ "server" ];
      ports = [ (myConstants.bind myConstants.services.authentik.port) ];

      environment = commonEnv // {
        AUTHENTIK_LISTEN__HTTP = "0.0.0.0:${toString myConstants.services.authentik.port}";
      };
      environmentFiles = [ envFile ];
      volumes = [ "/var/lib/authentik/media:/media" "/var/lib/authentik/custom-templates:/templates" ];
      # Find the database by name
      extraOptions = [ 
        "--add-host=host.docker.internal:host-gateway" 
        "--link=${myConstants.services.authentik-db.containerName}:${myConstants.services.authentik-db.containerName}" 
        "--link=${myConstants.services.authentik-redis.containerName}:${myConstants.services.authentik-redis.containerName}" 
      ];
    };

    # The Database
    ${myConstants.services.authentik-db.containerName} = {
      image = "docker.io/library/postgres:${myConstants.services.authentik-db.version}";
      environment = {
        POSTGRES_DB = "authentik";
        POSTGRES_USER = "authentik";
      };
      environmentFiles = [ envFile ];
      volumes = [ "/var/lib/authentik/postgres:/var/lib/postgresql/data" ];
      ports = [ "127.0.0.1:${toString myConstants.services.authentik-db.port}:6379" ];
    };

    # The Cache
    ${myConstants.services.authentik-redis.containerName} = {
      image = "docker.io/library/redis:${toString myConstants.services.authentik-redis.version}";
      cmd = [ "redis-server" "--maxmemory" "256mb" "--maxmemory-policy" "allkeys-lru" ];
      ports = [ "127.0.0.1:${toString myConstants.services.authentik-redis.port}:6379" ];
    };

    # The Worker
    ${myConstants.services.authentik-worker.containerName} = {
      image = "ghcr.io/goauthentik/server:${toString myConstants.services.authentik-worker.version}";
      dependsOn = [ (myConstants.services.authentik-db.containerName) (myConstants.services.authentik-redis.containerName) ];
      cmd = [ "worker" ];
      environment = commonEnv;
      environmentFiles = [ envFile ];
      volumes = [ "/var/lib/authentik/media:/media" "/var/lib/authentik/certs:/certs" ];
      extraOptions = [ 
        "--link=${myConstants.services.authentik-db.containerName}:${myConstants.services.authentik-db.containerName}" 
        "--link=${myConstants.services.authentik-redis.containerName}:${myConstants.services.authentik-redis.containerName}" 
      ];
    };
  };
} 