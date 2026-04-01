{ config, pkgs, myConstants, ... }:

{
  # Create the folders for your ROMs and database
  systemd.tmpfiles.rules =[
    # 4TB HDD: ROMs and Boxart
    "d ${myConstants.paths.services4TB}/romm/library 0777 root root -"
    "d ${myConstants.paths.services4TB}/romm/assets 0777 root root -"
    
    # SSD: Config, Resources, Redis and DB
    "d ${myConstants.paths.servicesSSD}/romm/resources 0777 root root -"
    "d ${myConstants.paths.servicesSSD}/romm/config 0777 root root -"
    "d ${myConstants.paths.servicesSSD}/romm/redis 0777 root root -"
    "d ${myConstants.paths.servicesSSD}/romm/secrets 0700 root root -"
    "d ${myConstants.paths.servicesSSD}/romm/db 0777 root root -"
  ];

  virtualisation.oci-containers.containers = {
    ${myConstants.services.romm.containerName} = {
      image = "ghcr.io/rommapp/romm:${toString myConstants.services.romm.version}";
      ports =[ "0.0.0.0:${toString myConstants.services.romm.port}:8080" ];
      environmentFiles = [ "${myConstants.paths.servicesSSD}/romm/secrets/secrets.env" ];
      environment = {
        DB_HOST = "romm-db";
        DB_NAME = "romm";
        DB_USER = "romm_user";

        REDIS_HOST = myConstants.services.romm-redis.containerName;

        # OIDC config
        OIDC_ENABLED = "true";
        OIDC_PROVIDER = "authentik";
        OIDC_REDIRECT_URI = "https://${toString myConstants.services.romm.subdomain}.${toString myConstants.publicDomain}/api/oauth/openid"; 
        OIDC_SERVER_APPLICATION_URL = "https://${toString myConstants.services.authentik.subdomain}.${toString myConstants.publicDomain}/application/o/romm/";
        DISABLE_USERPASS_LOGIN = "true";

        # Metadata provider
        # For secrets, see the secret.env file
        HASHEOUS_API_ENABLED = "true";
        PLAYMATCH_API_ENABLED = "true";
        LAUNCHBOX_API_ENABLED = "true";
        FLASHPOINT_API_ENABLED = "true";
        HLTB_API_ENABLED = "true"; 
      };
      volumes =[
        "${myConstants.paths.services4TB}/romm/library:/romm/library"
        "${myConstants.paths.services4TB}/romm/assets:/romm/assets"
        "${myConstants.paths.servicesSSD}/romm/resources:/romm/resources"
        "${myConstants.paths.servicesSSD}/romm/config:/romm/config"
      ];
      dependsOn = [ 
        myConstants.services.romm-db.containerName 
        myConstants.services.romm-redis.containerName 
      ];
      extraOptions = [ 
        "--link=${toString myConstants.services.romm-db.containerName}:${toString myConstants.services.romm-db.containerName}" 
        "--link=${toString myConstants.services.romm-redis.containerName}:${toString myConstants.services.romm-redis.containerName}" 
      ]; 
    };

    ${myConstants.services.romm-db.containerName} = {
      image = "mariadb:${toString myConstants.services.romm-db.version}";
      environmentFiles = [ "${myConstants.paths.servicesSSD}/romm/secrets/secrets.env" ];
      environment = {
        MARIADB_DATABASE = "romm";
        MARIADB_USER = "romm_user";
      };
      volumes =[
        "${myConstants.paths.servicesSSD}/romm/db:/var/lib/mysql"
      ];
    };

    ${myConstants.services.romm-redis.containerName} = {
      image = "redis:${toString myConstants.services.romm-redis.version}";
      volumes = [ "${myConstants.paths.servicesSSD}/romm/redis:/data" ];
    };

  };
}