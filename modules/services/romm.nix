{ config, pkgs, myConstants, ... }:

{
  # Create the folders for your ROMs and database
  systemd.tmpfiles.rules =[
    "d /mnt/storage/services/romm/library 0777 root root -"
    "d /mnt/storage/services/romm/assets 0777 root root -"
    "d /mnt/storage/services/romm/resources 0777 root root -"
    "d /mnt/storage/services/romm/config 0777 root root -"
    "d /mnt/storage/services/romm/redis 0777 root root -" # Ajouté pour Redis
    "d /var/lib/romm 0700 root root -" # Folder for secrets
    "d /var/lib/romm-db 0777 root root -"
  ];

  virtualisation.oci-containers.containers = {
    ${myConstants.services.romm.containerName} = {
      image = "ghcr.io/rommapp/romm:${toString myConstants.services.romm.version}";
      ports =[ "0.0.0.0:${toString myConstants.services.romm.port}:8080" ];
      environmentFiles = [ "/var/lib/romm/secrets.env" ];
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
      };
      volumes =[
        "/mnt/storage/services/romm/library:/romm/library"
        "/mnt/storage/services/romm/assets:/romm/assets"
        "/mnt/storage/services/romm/resources:/romm/resources"
        "/mnt/storage/services/romm/config:/romm/config"
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
      environmentFiles = [ "/var/lib/romm/secrets.env" ];
      environment = {
        MARIADB_DATABASE = "romm";
        MARIADB_USER = "romm_user";
      };
      volumes =[
        "/var/lib/romm-db:/var/lib/mysql"
      ];
    };

    ${myConstants.services.romm-redis.containerName} = {
      image = "redis:${toString myConstants.services.romm-redis.version}";
      volumes = [ "/mnt/storage/services/romm/redis:/data" ];
    };

  };
}