{ config, pkgs, myConstants, ... }:

let
  pipedDir = "${myConstants.paths.servicesSSD}/piped";
  
  # Dynamically generate the Java config file required by Piped Backend
  configProps = pkgs.writeText "config.properties" ''
    # The port to Listen on
    PORT: 8080
    # The number of workers to use for the server
    HTTP_WORKERS: 2
    # Proxy
    PROXY_PART: https://${myConstants.services.piped-proxy.subdomain}.${myConstants.publicDomain}
    # Public API URL
    API_URL: https://${myConstants.services.piped-backend.subdomain}.${myConstants.publicDomain}
    # Public Frontend URL
    FRONTEND_URL: https://${myConstants.services.piped-frontend.subdomain}.${myConstants.publicDomain}
    # Disable Registration (Set to true after you create your account!)
    DISABLE_REGISTRATION: false
    # PostgreSQL connection (Linked via Docker internal network)
    hibernate.connection.url: jdbc:postgresql://${myConstants.services.piped-db.containerName}:5432/piped
    hibernate.dialect: org.hibernate.dialect.PostgreSQLDialect
    hibernate.connection.username: piped
    hibernate.connection.password: piped_secure_password
  '';
in
{
  virtualisation.oci-containers.containers = {
    
    # 1. Piped Database
    ${myConstants.services.piped-db.containerName} = {
      image = "docker.io/library/postgres:${myConstants.services.piped-db.version}";
      environment = {
        POSTGRES_DB = "piped";
        POSTGRES_USER = "piped";
        POSTGRES_PASSWORD = "piped_secure_password";
      };
      volumes = [ "${pipedDir}/db:/var/lib/postgresql/data" ];
    };

    # 2. Piped Backend (API)
    ${myConstants.services.piped-backend.containerName} = {
      image = "1337kavin/piped:${myConstants.services.piped-backend.version}";
      dependsOn = [ myConstants.services.piped-db.containerName ];
      # Internal port is 8080
      ports = [ "172.17.0.1:${toString myConstants.services.piped-backend.port}:8080" ];
      volumes = [ "${configProps}:/app/config.properties:ro" ];
      extraOptions = [ 
        "--link=${myConstants.services.piped-db.containerName}:${myConstants.services.piped-db.containerName}" 
      ];
    };

    # 3. Piped Proxy (Video Streamer)
    ${myConstants.services.piped-proxy.containerName} = {
      image = "1337kavin/piped-proxy:${myConstants.services.piped-proxy.version}";
      # Internal port is 8080
      ports = [ "172.17.0.1:${toString myConstants.services.piped-proxy.port}:8080" ];
    };

    # 4. Piped Frontend (Web UI)
    ${myConstants.services.piped-frontend.containerName} = {
      image = "1337kavin/piped-frontend:${myConstants.services.piped-frontend.version}";
      environment = {
        BACKEND_HOSTNAME = "${myConstants.services.piped-backend.subdomain}.${myConstants.publicDomain}";
        HTTP_PORT = "80"; # Ensure Nginx listens on 80 internally
      };
      # Internal port is 80
      ports = [ "172.17.0.1:${toString myConstants.services.piped-frontend.port}:80" ];
    };

  };
}