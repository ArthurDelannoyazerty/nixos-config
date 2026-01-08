{ config, pkgs, myConstants, ... }:

let
  envFile = "/var/lib/authentik/secrets.env";
in
{
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

    # 3. The Main Server
    authentik-server = {
      image = "ghcr.io/goauthentik/server:2024.12.3";
      dependsOn = [ "authentik-db" "authentik-redis" ];
      ports = [ (myConstants.bind myConstants.services.authentik.port) ];
      environment = {
        AUTHENTIK_REDIS__HOST = "authentik-redis";
        AUTHENTIK_POSTGRESQL__HOST = "authentik-db";
        AUTHENTIK_POSTGRESQL__USER = "authentik";
        AUTHENTIK_POSTGRESQL__NAME = "authentik";
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
      environment = {
        AUTHENTIK_REDIS__HOST = "authentik-redis";
        AUTHENTIK_POSTGRESQL__HOST = "authentik-db";
      };
      environmentFiles = [ envFile ];
      volumes = [ "/var/lib/authentik/media:/media" "/var/lib/authentik/certs:/certs" ];
      extraOptions = [ 
        "--link=authentik-db:authentik-db" 
        "--link=authentik-redis:authentik-redis" 
      ];
    };
  };
}