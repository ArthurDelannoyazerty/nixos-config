{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers."${myConstants.services.forgejo.containerName}" = {
    image = "codeberg.org/forgejo/forgejo:${myConstants.services.forgejo.version}";
    
    ports = [ (myConstants.bind myConstants.services.forgejo.port) ];

    environment = {
      USER_UID = "1000";
      USER_GID = "1000";

      FORGEJO__server__APP_DATA_PATH = "/data/data";
      FORGEJO__repository__ROOT = "/data/repositories";
      FORGEJO__log__ROOT_PATH = "/data/log";
      FORGEJO__attachment__PATH = "/data/data/attachments";
      FORGEJO__picture__AVATAR_UPLOAD_PATH = "/data/data/avatars";
      FORGEJO__picture__REPOSITORY_AVATAR_UPLOAD_PATH = "/data/data/repo-avatars";

      FORGEJO__security__INSTALL_LOCK = "true";
      FORGEJO__server__DISABLE_SSH = "true";
      
      # LFS Configuration
      FORGEJO__server__LFS_START_SERVER = "true";
      FORGEJO__lfs__PATH = "/data/lfs";
      
      # Database mapping
      FORGEJO__database__DB_TYPE = "sqlite3";
      FORGEJO__database__PATH = "/data/data/forgejo.db"; 

      # Server Configuration
      FORGEJO__server__DOMAIN = "${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}";
      FORGEJO__server__ROOT_URL = "https://${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}/";
      
      # Your custom port helper binds 8083:8083, so the container must listen on 8083 internally
      FORGEJO__server__HTTP_PORT = toString myConstants.services.forgejo.port;
      
      FORGEJO__webhook__ALLOWED_HOST_LIST = "127.0.0.1";
      
      FORGEJO__mirror__ENABLED = "true";
      FORGEJO__mirror__DEFAULT_INTERVAL = "8h";

      # Security & Reverse Proxy (Authentik)
      FORGEJO__service__ENABLE_REVERSE_PROXY_AUTHENTICATION = "true";
      FORGEJO__service__ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = "true";
      FORGEJO__service__ENABLE_REVERSE_PROXY_EMAIL = "true";
      
      FORGEJO__security__REVERSE_PROXY_AUTHENTICATION_USER = "X-Authentik-Username";
      FORGEJO__security__REVERSE_PROXY_AUTHENTICATION_EMAIL = "X-Authentik-Email";
      
      # We add '172.16.0.0/12' so Forgejo trusts Authentik headers coming through the Docker bridge network
      FORGEJO__security__REVERSE_PROXY_TRUSTED_PROXIES = "127.0.0.1/32, ::1/128, 172.16.0.0/12";
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/forgejo:/data"
      "/etc/localtime:/etc/localtime:ro"
    ];
  };
}