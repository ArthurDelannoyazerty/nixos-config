{ config, pkgs, myConstants, ... }:

let 
  port = myConstants.services.nextcloud.port;
  dbPort = 5433;
  redisPort = 6380;

  # Nix creates an executable script in the Nix Store
  debloatScript = pkgs.writeScript "nextcloud-debloat.sh" ''
    #!/bin/sh
    echo "=== Running Nextcloud Auto-Debloat ==="
    
    # Disable bloated apps
    php occ app:disable photos activity dashboard weather contacts calendar firstrunwizard nextcloud_announcements || true
    
    # Enable external storage (Needed for the Paperless connection)
    php occ app:enable files_external || true
    
    # Make "Files" the default page upon login
    php occ config:system:set default_app --value="files" || true
    
    echo "=== Debloat complete! ==="
  '';
in {
  virtualisation.oci-containers.containers = {
    nextcloud-db = {
      image = "postgres:15-alpine";
      environment = {
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
      };
      environmentFiles =[ "/var/lib/nextcloud/secrets.env" ];
      ports =[ "127.0.0.1:${toString dbPort}:5432" ];
      volumes =[ "/mnt/storage/services/nextcloud/db:/var/lib/postgresql/data" ];
    };

    nextcloud-redis = {
      image = "redis:alpine";
      ports =[ "127.0.0.1:${toString redisPort}:6379" ];
      volumes =[ "/mnt/storage/services/nextcloud/redis:/data" ];
    };

    nextcloud-app = {
      image = "nextcloud:${myConstants.services.nextcloud.version}";
      ports =[ (myConstants.bind port) ];
      environment = {
        POSTGRES_HOST = "172.17.0.1:${toString dbPort}";
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        REDIS_HOST = "172.17.0.1";
        REDIS_HOST_PORT = "${toString redisPort}";
      };
      environmentFiles =[ "/var/lib/nextcloud/secrets.env" ];
      volumes =[ 
        "/mnt/storage/services/nextcloud/app:/var/www/html" 
        "/mnt/storage/services/nextcloud/data:/var/www/html/data" 
        "/mnt/storage/services/paperless/consume:/paperless-consume"  # Mount the shared Paperless consume folder inside Nextcloud
        "${debloatScript}:/docker-entrypoint-hooks.d/post-installation/01-debloat.sh:ro"  # Inject our Auto-Debloat script into the Docker entrypoint hooks
      ];
      dependsOn =[ "nextcloud-db" "nextcloud-redis" ];
    };
  };
}