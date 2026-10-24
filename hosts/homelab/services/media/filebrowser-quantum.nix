{ config, pkgs, myConstants, ... }:

let
  filebrowserConfig = pkgs.writeText "filebrowser-config.yaml" ''
    http:
      port: 80
      externalUrl: "https://${myConstants.services.filebrowser-quantum.subdomain}.${myConstants.publicDomain}"
      internalUrl: "http://172.17.0.1:${toString myConstants.services.filebrowser-quantum.port}"
      trustProxyHeaders: true

    server:
      database:
        path: "/home/filebrowser/data/database.sqlite"
      cacheDir: "/home/filebrowser/data/tmp"
      
      sources:
        - path: "/srv"
          name: "Personal Files"
          config:
            defaultEnabled: true
            createUserDir: true
            defaultUserScope: "/"

        - path: "/admin-view"
          name: "All Users (Admin View)"
          config:
            defaultEnabled: false

        - path: "/media"
          name: "Media"
          config:
            defaultEnabled: false

        - path: "/minecraft"
          name: "Minecraft"
          config:
            defaultEnabled: false

        - path: "/immich"
          name: "Immich Photos"
          config:
            defaultEnabled: false

        - path: "/downloads"
          name: "Downloads"
          config:
            defaultEnabled: false


    integrations:
      office:
        url: "https://${myConstants.services.onlyoffice.subdomain}.${myConstants.publicDomain}"
        internalUrl: "http://172.17.0.1:${toString myConstants.services.onlyoffice.port}"

    auth:
      tokenExpirationHours: 48
      methods:
        password:
          enabled: true
        oidc:
          enabled: true
          issuerUrl: "https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/application/o/${myConstants.services.filebrowser-quantum.subdomain}/"
          scopes: "email openid profile groups"
          userIdentifier: "preferred_username"
          createUser: true
          adminGroup: "authentik Admins"
  '';
in
{
  # Ensure the necessary persistent directories exist before Docker starts
  systemd.tmpfiles.rules =[
    "d ${myConstants.paths.servicesSSD}/filebrowser-quantum 0750 1000 1000 -"
    "d ${myConstants.paths.servicesSSD}/filebrowser-quantum/data 0750 1000 1000 -"
    "d ${myConstants.paths.services4TB}/filebrowser-quantum/files 0750 1000 1000 -"
  ];

  virtualisation.oci-containers.containers."${toString myConstants.services.filebrowser-quantum.containerName}" = {
    image = "gtstef/filebrowser:${myConstants.services.filebrowser-quantum.version}";
    
    dependsOn = [ "${myConstants.services.authentik.containerName}" ];

    user = "1000:1000";

    volumes =[
      # Config and personal files
      "${myConstants.paths.servicesSSD}/filebrowser-quantum/data:/home/filebrowser/data"
      
      # Personal files mapped for users
      "${myConstants.paths.services4TB}/filebrowser-quantum/files:/srv"
      
      # The exact same folder mapped to a different path so Admins can view all users
      "${myConstants.paths.services4TB}/filebrowser-quantum/files:/admin-view"
      
      # Additional Admin Storage Sources
      "${myConstants.paths.disk4TB}/media:/media"
      "${myConstants.paths.disk4TB}/downloads:/downloads"
      "${myConstants.paths.servicesSSD}/crafty/servers:/minecraft"
      "${myConstants.paths.services4TB}/immich/photos:/immich"

      "/mnt/old-hdd1-p1:/old-hdd1-p1"
      "/mnt/old-hdd1-p2:/old-hdd1-p2"

      "${filebrowserConfig}:/home/filebrowser/data/config.yaml:ro"
    ];

    environmentFiles =[
      "${myConstants.paths.servicesSSD}/filebrowser-quantum/secrets.env"
    ];

    environment = {
      FILEBROWSER_CONFIG = "/home/filebrowser/data/config.yaml";
    };

    ports =[
      "0.0.0.0:${toString myConstants.services.filebrowser-quantum.port}:80"
    ];
  };

  systemd.services."docker-${toString myConstants.services.filebrowser-quantum.containerName}" = {
    # Wait 10 seconds between restart attempts
    serviceConfig.RestartSec = "10s";
    
    # Disable the systemd limit that gives up after too many rapid failures
    # unitConfig.StartLimitIntervalSec = 0;
  };
}
