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
    "d /var/lib/romm-db 0777 root root -"
  ];

  virtualisation.oci-containers.containers = {
    "romm" = {
      image = "ghcr.io/rommapp/romm:${toString version}";
      ports =[ "127.0.0.1:${toString port}:8080" ];
      environment = {
        DB_HOST = "romm-db";
        DB_NAME = "romm";
        DB_USER = "romm_user";
        DB_PASSWD = "YourStrongDatabasePassword";
        ROMM_AUTH_SECRET_KEY = "GenerateARandomStringHere";
      };
      volumes =[
        "/mnt/storage/services/romm/library:/romm/library"
        "/mnt/storage/services/romm/assets:/romm/assets"
        "/mnt/storage/services/romm/config:/romm/config"
      ];
      dependsOn = [ "romm-db" ];
    };

    "romm-db" = {
      image = "mariadb:11";
      environment = {
        MARIADB_ROOT_PASSWORD = "YourStrongRootPassword";
        MARIADB_DATABASE = "romm";
        MARIADB_USER = "romm_user";
        MARIADB_PASSWORD = "YourStrongDatabasePassword";
      };
      volumes =[
        "/var/lib/romm-db:/var/lib/mysql"
      ];
    };
  };
}