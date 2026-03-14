{ config, pkgs, myConstants, ... }:
let
  port = myConstants.services.romm.port;
  version = myConstants.services.romm.version;
in
{
  # Create the folders for your ROMs and database
  systemd.tmpfiles.rules =[
    "d /mnt/storage/services/romm/library 0777 root root -"
    "d /mnt/storage/services/romm/assets 0777 root root -"
    "d /mnt/storage/services/romm/config 0777 root root -"
    "d /var/lib/romm 0700 root root -" # Folder for secrets
    "d /var/lib/romm-db 0777 root root -"
  ];

  virtualisation.oci-containers.containers = {
    "romm" = {
      image = "ghcr.io/rommapp/romm:${toString version}";
      ports =[ "0.0.0.0:${toString port}:8080" ];
      environmentFiles = [ "/var/lib/romm/secrets.env" ];
      environment = {
        DB_HOST = "romm-db";
        DB_NAME = "romm";
        DB_USER = "romm_user";
        # OIDC config
        OIDC_ENABLED = "true";
        OIDC_PROVIDER = "authentik";
        OIDC_REDIRECT_URI = "https://romm.arthur-lab.com/api/oauth/openid"; 
        OIDC_SERVER_APPLICATION_URL = "https://authentik.arthur-lab.com/application/o/romm/";
        DISABLE_USERPASS_LOGIN = "true";
      };
      volumes =[
        "/mnt/storage/services/romm/library:/romm/library"
        "/mnt/storage/services/romm/assets:/romm/assets"
        "/mnt/storage/services/romm/config:/romm/config"
      ];
      dependsOn = [ "romm-db" ];

      # Explicitly link the database container so DNS resolves correctly!
      extraOptions = [ "--link=romm-db:romm-db" ]; 
    };

    "romm-db" = {
      image = "mariadb:11";
      environmentFiles = [ "/var/lib/romm/secrets.env" ];
      environment = {
        MARIADB_DATABASE = "romm";
        MARIADB_USER = "romm_user";
      };
      volumes =[
        "/var/lib/romm-db:/var/lib/mysql"
      ];
    };
  };
}