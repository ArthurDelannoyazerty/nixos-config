{ config, pkgs, myConstants, ... }:

let
  cfg = myConstants.services.filebrowser-quantum;
in
{
  systemd.tmpfiles.rules =[
    "d /var/lib/filebrowser-quantum 0750 root root -"
    "d /var/lib/filebrowser-quantum/data 0750 root root -"
    "d /mnt/storage/services/filebrowser-quantum/files 0750 root root -"
  ];

  virtualisation.oci-containers.containers."filebrowser-quantum" = {
    image = "gtstef/filebrowser:${cfg.version}";
    
    volumes =[
      "/var/lib/filebrowser-quantum/data:/home/filebrowser/data"
      "/mnt/storage/services/filebrowser-quantum/files:/srv"
    ];

    environmentFiles =[
      "/var/lib/filebrowser-quantum/secrets.env"
    ];

    environment = {
      FILEBROWSER_CONFIG = "/home/filebrowser/data/config.yaml";
    };

    ports =[
      "${myConstants.bind cfg.port}:80"
    ];
  };
}