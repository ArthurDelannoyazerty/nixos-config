{ config, pkgs, myConstants, ... }:

let 
  port = myConstants.services.nextcloud.port;
  dbPort = 5435; 
  redisPort = 6382;
  
  # Construct the full domain string
  fullDomain = "${myConstants.services.nextcloud.subdomain}.${myConstants.publicDomain}";

  debloatScript = pkgs.writeScript "nextcloud-debloat.sh" ''
    #!/bin/sh
    echo "=== Running Nextcloud Auto-Debloat ==="
    
    # Disable bloated apps
    php occ app:disable photos activity dashboard weather contacts calendar firstrunwizard nextcloud_announcements || true
    
    # Enable external storage (Needed for the Paperless connection)
    php occ app:enable files_external || true
    
    # Make "Files" the default page upon login
    php occ config:system:set default_app --value="files" || true
    
    # Force trusted domains & proxies (catches cases where the env vars get ignored on pre-existing databases)
    php occ config:system:set trusted_domains 1 --value="${fullDomain}" || true
    php occ config:system:set trusted_proxies 0 --value="172.17.0.1" || true
    
    # Installation de l'application OIDC si absente
    if ! php occ app:list | grep -q user_oidc; then
      php occ app:install user_oidc
    fi

    # Configuration du fournisseur Authentik
    # Remplace l'URL par la tienne (trouvée dans Authentik > Applications > Nextcloud > Provider)
    php occ user_oidc:provider:create Authentik \
      "https://authentik.${myConstants.publicDomain}/application/o/nextcloud/" \
      "$NEXTCLOUD_OIDC_CLIENT_ID" \
      "$NEXTCLOUD_OIDC_CLIENT_SECRET" \
      --display-name="Authentik SSO" || true

    # 3. (OPTIONNEL) Désactiver le login local (À FAIRE SEULEMENT APRÈS TEST RÉUSSI)
    # php occ config:system:set login_form_enabled --type=boolean --value=false || true
  
    echo "=== Config complete! ==="
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
      ports =[ "172.17.0.1:${toString dbPort}:5432" ];
      volumes =[ "/mnt/storage/services/nextcloud/db:/var/lib/postgresql/data" ];
    };

    nextcloud-redis = {
      image = "redis:alpine";
      ports =[ "172.17.0.1:${toString redisPort}:6379" ];
      volumes =[ "/mnt/storage/services/nextcloud/redis:/data" ];
    };

    nextcloud-app = {
      image = "nextcloud:${myConstants.services.nextcloud.version}";
      # Route the host port to internal port 80
      ports =[ "0.0.0.0:${toString port}:80" ]; 
      
      environment = {
        POSTGRES_HOST = "172.17.0.1:${toString dbPort}";
        POSTGRES_DB = "nextcloud";
        POSTGRES_USER = "nextcloud";
        REDIS_HOST = "172.17.0.1";
        REDIS_HOST_PORT = "${toString redisPort}";
        
        # Declarative Trusted Domains & Proxies
        NEXTCLOUD_TRUSTED_DOMAINS = fullDomain;
        TRUSTED_PROXIES = "172.17.0.1";
      };
      
      environmentFiles =[ "/var/lib/nextcloud/secrets.env" ];
      volumes =[ 
        "/mnt/storage/services/nextcloud/app:/var/www/html" 
        "/mnt/storage/services/nextcloud/data:/var/www/html/data" 
        "/mnt/storage/services/paperless/consume:/paperless-consume"  # Mount the shared Paperless consume folder inside Nextcloud
        "${debloatScript}:/docker-entrypoint-hooks.d/before-starting/01-debloat.sh:ro"  # Inject our Auto-Debloat script into the Docker entrypoint hooks
      ];
      dependsOn =[ "nextcloud-db" "nextcloud-redis" ];
    };
  };
}