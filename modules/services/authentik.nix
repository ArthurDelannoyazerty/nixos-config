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
    AUTHENTIK_REDIS__HOST = "authentik-redis";
    AUTHENTIK_POSTGRESQL__HOST = "authentik-db";
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
    uid = 1000;
    group = "authentik";
  };

  virtualisation.oci-containers.containers = {
    # 1. The Database
    authentik-db = {
      image = "docker.io/library/postgres:16-alpine";
      environment = {
        POSTGRES_DB = "authentik";
        POSTGRES_USER = "authentik";
      };
      environmentFiles = [ envFile ];
      volumes = [ "/var/lib/authentik/postgres:/var/lib/postgresql/data" ];
    };

    # 2. The Cache
    authentik-redis = {
      image = "docker.io/library/redis:alpine";
      cmd = [ "redis-server" "--maxmemory" "256mb" "--maxmemory-policy" "allkeys-lru" ];
    };

    # 3. Server
    authentik-server = {
      image = "ghcr.io/goauthentik/server:2024.12.3";
      dependsOn = [ "authentik-db" "authentik-redis" ];
      cmd = [ "server" ];
      ports = [ (myConstants.bind myConstants.services.authentik.port) ];

      environment = commonEnv // {
        AUTHENTIK_LISTEN__HTTP = "0.0.0.0:9000";
      };
      environmentFiles = [ envFile ];
      volumes = [ "/var/lib/authentik/media:/media" "/var/lib/authentik/custom-templates:/templates" ];
      # Find the database by name
      extraOptions = [ 
        "--link=authentik-db:authentik-db" 
        "--link=authentik-redis:authentik-redis" 
      ];
    };

    # 4. The Worker (Handles the heavy lifting)
    authentik-worker = {
      image = "ghcr.io/goauthentik/server:2024.12.3";
      dependsOn = [ "authentik-db" "authentik-redis" ];
      cmd = [ "worker" ];
      environment = commonEnv;
      environmentFiles = [ envFile ];
      volumes = [ "/var/lib/authentik/media:/media" "/var/lib/authentik/certs:/certs" ];
      extraOptions = [ 
        "--link=authentik-db:authentik-db" 
        "--link=authentik-redis:authentik-redis" 
      ];
    };
  };
}