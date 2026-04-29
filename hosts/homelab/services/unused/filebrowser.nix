{ config, pkgs, myConstants, ... }:
{
  systemd.tmpfiles.rules = [
    "d /var/lib/filebrowser 0750 1000 1000 -"
    "d /var/lib/filebrowser/database 0750 1000 1000 -"
    "d /var/lib/filebrowser/config 0750 1000 1000 -"
    
    # Storage directory permissions
    "d /mnt/storage/services/filebrowser 0750 1000 1000 -"
    "z /mnt/storage/services/filebrowser 0750 1000 1000 -"  
  ];

  virtualisation.oci-containers.containers.filebrowser = {
    image = "filebrowser/filebrowser:latest";
    ports = [  "${toString myConstants.services.filebrowser.port}:80" ];
    user = "1000:1000";
    
    environment = {
      FB_AUTH_METHOD = "proxy";
      FB_AUTH_HEADER = "X-Authentik-Username";
      FB_DATABASE = "/database/filebrowser.db";
      FB_CONFIG = "/config/settings.json";
    };

    volumes = [
      "/mnt/storage/services/filebrowser:/srv"
      "/var/lib/filebrowser/database:/database"
      "/var/lib/filebrowser/config:/config"
    ];

  };
}