{ config, myConstants, ... }:

{
  # Pre-create the directories to ensure correct permissions (UID 1000)
  systemd.tmpfiles.rules =[
    "d ${myConstants.paths.servicesSSD}/tranga 0755 1000 1000 -"
    "d ${myConstants.paths.servicesSSD}/tranga/postgres 0755 1000 1000 -"
    "d ${myConstants.paths.disk4TB}/services/tranga/downloads 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers = {
    
    # 1. Tranga Database
    "${myConstants.services.tranga-db.containerName}" = {
      image = "postgres:${myConstants.services.tranga-db.version}";
      environment = {
        POSTGRES_DB = "postgres";
        POSTGRES_USER = "postgres";
        # In a real environment, you might want to move this to an .env file
        POSTGRES_PASSWORD = "postgres_secret_password"; 
      };
      volumes = [
        "${myConstants.paths.servicesSSD}/tranga/postgres:/var/lib/postgresql/data"
      ];
    };

    # 2. Tranga API (The Core Worker)
    "${myConstants.services.tranga-api.containerName}" = {
      image = "glax/tranga-api:${myConstants.services.tranga-api.version}";
      dependsOn = [ myConstants.services.tranga-db.containerName ];
      
      # Internal port for Tranga API is 6531. We bind it to localhost for Caddy.
      ports = [ "127.0.0.1:${toString myConstants.services.tranga-api.port}:6531" ];
      
      environment = {
        TZ = "Europe/Paris";
        POSTGRES_HOST = myConstants.services.tranga-db.containerName;
        POSTGRES_USER = "postgres";
        POSTGRES_PASSWORD = "postgres_secret_password"; # Must match DB above
      };

      volumes = [
        # Configurations and Logs
        "${myConstants.paths.servicesSSD}/tranga:/usr/share/tranga-api"
        # Download directory mapped to your bulk 4TB disk
        "${myConstants.paths.disk4TB}/services/tranga/downloads:/Manga" 
      ];

      extraOptions = [
        # Link containers internally so the API can resolve the DB hostname
        "--link=${myConstants.services.tranga-db.containerName}:${myConstants.services.tranga-db.containerName}"
      ];
    };

    # 3. Tranga Website (The Nuxt Frontend)
    "${myConstants.services.tranga.containerName}" = {
      image = "glax/tranga-website:${myConstants.services.tranga.version}";
      dependsOn = [ myConstants.services.tranga-api.containerName ];
      
      # The frontend image listens on port 80 internally
      ports = [ "127.0.0.1:${toString myConstants.services.tranga.port}:80" ];
    };
  };
}