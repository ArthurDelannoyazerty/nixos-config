{ config, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.kaizoku.containerName}" = {
    image = "ghcr.io/oae/kaizoku:${myConstants.services.kaizoku.version}";

    ports =[ (myConstants.bind myConstants.services.kaizoku.port) ];

    environment = {
      PUID = "1000"; 
      PGID = "1000"; 
      TZ = "Europe/Paris";
      
      # Web UI Port
      KAIZOKU_PORT = toString myConstants.services.kaizoku.port;
      
      # Database connection 
      DATABASE_URL = "postgresql://kaizoku:kaizoku@${services.kaizoku-db.containerName}:${toString services.kaizoku-db.port}/kaizoku";

      # Redis connection
      REDIS_HOST = "${services.kaizoku-redis.containerName}";
      REDIS_PORT = "6379";
    };

    volumes =[
      "${myConstants.paths.servicesSSD}/kaizoku/config:/config"
      "${myConstants.paths.servicesSSD}/kaizoku/logs:/logs"
      "${myConstants.paths.disk4TB}/media/manga:/data" 
    ];

    dependsOn = [ 
      "${myConstants.services.kaizoku-db.containerName}", 
      "${myConstants.services.kaizoku-redis.containerName}" 
    ];
  };

  virtualisation.oci-containers.containers."${myConstants.services.kaizoku-db.containerName}" = {
    image = "postgres:${myConstants.services.kaizoku-db.version}";
    
    environment = {
      POSTGRES_USER = "kaizoku";
      POSTGRES_PASSWORD = "kaizoku";
      POSTGRES_DB = "kaizoku";
    };

    volumes =[
      "${myConstants.paths.servicesSSD}/kaizoku/db:/var/lib/postgresql/data"
    ];
  };

  virtualisation.oci-containers.containers."${myConstants.services.kaizoku-redis.containerName}" = {
    image = "redis:${myConstants.services.kaizoku-redis.version}";
  };
}