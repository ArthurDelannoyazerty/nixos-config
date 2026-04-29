{ config, pkgs, myConstants, ... }:

let 
  port = myConstants.services.paperless-ngx.port;
  dbPort = 5436;
  redisPort = 6381;
in {
  virtualisation.oci-containers.containers = {
    paperless-db = {
      image = "postgres:15-alpine";
      environment = {
        POSTGRES_DB = "paperless";
        POSTGRES_USER = "paperless";
      };
      environmentFiles =[ "/var/lib/paperless/secrets.env" ];
      ports =[ "172.17.0.1:${toString dbPort}:5432" ];
      volumes =[ "/mnt/storage/services/paperless/db:/var/lib/postgresql/data" ];
    };

    paperless-redis = {
      image = "redis:alpine";
      ports =[ "172.17.0.1:${toString redisPort}:6379" ];
      volumes =[ "/mnt/storage/services/paperless/redis:/data" ];
    };

    paperless-app = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:${myConstants.services.paperless-ngx.version}";
      ports = [ (myConstants.bind port) ];
      environment = {
        # CRITICAL: We force Paperless to run as UID 33 (Nextcloud's www-data user).
        # This allows both containers to freely read/delete files in the shared consume folder.
        USERMAP_UID = "33";
        USERMAP_GID = "33";
        PAPERLESS_REDIS = "redis://172.17.0.1:${toString redisPort}";
        PAPERLESS_DBHOST = "172.17.0.1";
        PAPERLESS_DBPORT = "${toString dbPort}";
        PAPERLESS_DBNAME = "paperless";
        PAPERLESS_DBUSER = "paperless";
        PAPERLESS_URL = "https://${myConstants.services.paperless-ngx.subdomain}.${myConstants.publicDomain}";
        PAPERLESS_TIME_ZONE = "Europe/Paris";
        PAPERLESS_OCR_LANGUAGE = "fra+eng";

        # OIDC
        PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
        PAPERLESS_SOCIALACCOUNT_PROVIDERS = builtins.toJSON {
          openid_connect = {
            APPS = [{
              provider_id = "authentik";
              name = "Authentik";
              client_id = "$PAPERLESS_OIDC_CLIENT_ID";
              secret = "$PAPERLESS_OIDC_CLIENT_SECRET";
              settings = {
                server_url = "https://authentik.${myConstants.publicDomain}/application/o/paperless-ngx/.well-known/openid-configuration";
              };
            }];
          };
        };

        # Non Autorisation de la création automatique de compte
        PAPERLESS_ACCOUNT_ALLOW_SIGNUPS = "false";

        # Désactiver le login local (À FAIRE SEULEMENT APRÈS TEST RÉUSSI)
        # PAPERLESS_SOCIAL_ONLY = "true";
      };
      environmentFiles =[ "/var/lib/paperless/secrets.env" ];
      volumes =[ 
        "/mnt/storage/services/paperless/data:/usr/src/paperless/data" 
        "/mnt/storage/services/paperless/media:/usr/src/paperless/media" 
        "/mnt/storage/services/paperless/export:/usr/src/paperless/export" 
        "/mnt/storage/services/paperless/consume:/usr/src/paperless/consume"  # The shared consume folder mapped to Paperless
      ];
      dependsOn = [ "paperless-db" "paperless-redis" ];
    };
  };
}