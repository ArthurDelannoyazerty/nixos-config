{ config, pkgs, myConstants, ... }:

let
  # The secure file we just created
  envFile = "/var/lib/immich/secrets.env";
  
  # Shared Environment Variables (No passwords here)
  sharedEnv = {
    DB_HOSTNAME = "immich-db";
    DB_USERNAME = "postgres";
    DB_DATABASE_NAME = "immich";
    REDIS_HOSTNAME = myConstants.services.immich-redis.containerName;
    IMMICH_MACHINE_LEARNING_URL = "http://immich-machine-learning:3003";
    TZ = "Europe/Paris";
  };
in
{
  virtualisation.oci-containers.containers = {

    # The Server
    ${myConstants.services.immich.containerName} = {
      image = "ghcr.io/immich-app/immich-server:${myConstants.services.immich.version}";
      ports = [ (myConstants.bind myConstants.services.immich.port) ];
      dependsOn = [ 
        myConstants.services.immich-db.containerName 
        myConstants.services.immich-redis.containerName 
        myConstants.services.immich-machine-learning.containerName
      ];
      environment = sharedEnv;
      # Pulls DB_PASSWORD from the secure file
      environmentFiles = [ envFile ];
      volumes = [
        "/mnt/storage/services/immich/photos:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      extraOptions = [
        "--link=${myConstants.services.immich-db.containerName}:${myConstants.services.immich-db.containerName}"
        "--link=${myConstants.services.immich-redis.containerName}:${myConstants.services.immich-redis.containerName}"
        "--link=${myConstants.services.immich-machine-learning.containerName}:${myConstants.services.immich-machine-learning.containerName}"
        "--device=/dev/dri:/dev/dri" # Intel QuickSync Hardware Acceleration
      ];
    };
    
    # The Database
    ${myConstants.services.immich-db.containerName} = {
      image = "ghcr.io/immich-app/postgres:${myConstants.services.immich-db.version}";
      environment = {
        POSTGRES_USER = sharedEnv.DB_USERNAME;
        POSTGRES_DB = sharedEnv.DB_DATABASE_NAME;
        # Required parameter for the new database setup
        POSTGRES_INITDB_ARGS = "--data-checksums"; 
      };
      environmentFiles = [ envFile ];
      volumes = [ "/mnt/storage/services/immich/postgres:/var/lib/postgresql/data" ];
      ports = [ "127.0.0.1:${toString myConstants.services.immich-db.port}:5432" ]; 
    };

    # The Cache
    ${myConstants.services.immich-redis.containerName} = {
      image = "docker.io/library/redis:${myConstants.services.immich-redis.version}";
    };

    # Machine Learning
    ${myConstants.services.immich-machine-learning.containerName} = {
      image = "ghcr.io/immich-app/immich-machine-learning:${myConstants.services.immich-machine-learning.version}";
      dependsOn = [ myConstants.services.immich-db.containerName ]; 
      environment = sharedEnv;
      # Pulls DB_PASSWORD from the secure file
      environmentFiles = [ envFile ];
      volumes = [
        "/mnt/storage/services/immich/model-cache:/cache"
      ];
      extraOptions = [
        "--link=${myConstants.services.immich-db.containerName}:${myConstants.services.immich-db.containerName}"
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