{ config, pkgs, myConstants, ... }:

let
  filebrowserConfig = pkgs.writeText "filebrowser-config.yaml" ''
    server:
      port: 80
      database: "/home/filebrowser/data/database.db"
      cacheDir: "/home/filebrowser/data/tmp"
      sources:
        - path: "/srv"
          config:
            defaultEnabled: true
            createUserDir: true

    auth:
      methods:
        password:
          enabled: true
        oidc:
          enabled: true
          issuerUrl: "https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/application/o/${myConstants.services.filebrowser-quantum.subdomain}/"
          scopes: "email openid profile groups"
          userIdentifier: "preferred_username"
          createUser: true               # create user if it does not exist
          
          adminGroup: "authentik Admins" 
  '';

in
{
  # Ensure the necessary persistent directories exist before Docker starts
  systemd.tmpfiles.rules =[
    "d /var/lib/filebrowser-quantum 0750 root root -"
    "d /var/lib/filebrowser-quantum/data 0750 root root -"
    "d /mnt/storage/services/filebrowser-quantum/files 0750 root root -"
  ];

  virtualisation.oci-containers.containers."${toString myConstants.services.filebrowser-quantum.containerName}" = {
    image = "gtstef/filebrowser:${myConstants.services.filebrowser-quantum.version}";
    
    volumes =[
      "/var/lib/filebrowser-quantum/data:/home/filebrowser/data"
      "/mnt/storage/services/filebrowser-quantum/files:/srv"
      "${filebrowserConfig}:/home/filebrowser/data/config.yaml:ro"
    ];

    environmentFiles =[
      "/var/lib/filebrowser-quantum/secrets.env"
    ];

    environment = {
      FILEBROWSER_CONFIG = "/home/filebrowser/data/config.yaml";
    };

    ports =[
      "0.0.0.0:${toString myConstants.services.filebrowser-quantum.port}:80"
    ];
  };
}