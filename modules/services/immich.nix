{ config, pkgs, myConstants, ... }:

let
  # The secure file we just created
  envFile = "/var/lib/immich/secrets.env";
  
  # Shared Environment Variables (No passwords here!)
  sharedEnv = {
    DB_HOSTNAME = "immich-db";
    DB_USERNAME = "postgres";
    DB_DATABASE_NAME = "immich";
    REDIS_HOSTNAME = "immich-redis";
    IMMICH_MACHINE_LEARNING_URL = "http://immich-machine-learning:3003";
    TZ = "Europe/Paris";
  };
in
{
  virtualisation.oci-containers.containers = {
    
    # 1. The Database
    immich-db = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
      environment = {
        POSTGRES_USER = sharedEnv.DB_USERNAME;
        POSTGRES_DB = sharedEnv.DB_DATABASE_NAME;
        # Required parameter for the new database setup
        POSTGRES_INITDB_ARGS = "--data-checksums"; 
      };
      environmentFiles = [ envFile ];
      volumes = [ "/mnt/storage/services/immich/postgres:/var/lib/postgresql/data" ];
      ports = [ "127.0.0.1:5433:5432" ]; 
    };

    # 2. The Cache
    immich-redis = {
      image = "docker.io/library/redis:6.2-alpine";
    };

    # 3. The Main Server
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:${myConstants.services.immich.version}";
      ports = [ (myConstants.bind myConstants.services.immich.port) ];
      dependsOn = [ "immich-db" "immich-redis" "immich-machine-learning" ];
      environment = sharedEnv;
      # Pulls DB_PASSWORD from the secure file
      environmentFiles = [ envFile ];
      volumes = [
        "/mnt/storage/services/immich/photos:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      extraOptions = [
        "--link=immich-db:immich-db"
        "--link=immich-redis:immich-redis"
        "--link=immich-machine-learning:immich-machine-learning"
        "--device=/dev/dri:/dev/dri" # Intel QuickSync Hardware Acceleration
      ];
    };

    # 4. Machine Learning
    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:${myConstants.services.immich.version}";
      dependsOn = [ "immich-db" ]; 
      environment = sharedEnv;
      # Pulls DB_PASSWORD from the secure file
      environmentFiles = [ envFile ];
      volumes = [
        "/mnt/storage/services/immich/model-cache:/cache"
      ];
      extraOptions = [
        "--link=immich-db:immich-db"
      ];
    };
  };

  # Ensure the host directories exist with wide permissions 
  systemd.tmpfiles.rules = [
    "d /mnt/storage/services/immich/postgres 0777 root root -"
    "d /mnt/storage/services/immich/photos 0777 root root -"
    "d /mnt/storage/services/immich/model-cache 0777 root root -"
  ];


  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver        # Pilote moderne pour QuickSync (8ème gen+)
      intel-vaapi-driver        # Alternative pour la compatibilité
      libvdpau-va-gl
    ];
  };

}