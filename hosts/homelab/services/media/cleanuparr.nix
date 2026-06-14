{ config, pkgs, myConstants, ... }:

{
  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/cleanuparr 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers."${myConstants.services.cleanuparr.containerName}" = {
    image = "ghcr.io/cleanuparr/cleanuparr:${myConstants.services.cleanuparr.version}";

    ports = [ 
      (myConstants.bind myConstants.services.cleanuparr.port) 
    ];

    environment = {
      PORT = toString myConstants.services.cleanuparr.port;
      PUID = "1000";
      PGID = "1000";
      TZ = "Europe/Paris";
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/cleanuparr:/config"
      
      # Optional but highly recommended: Let Cleanuparr see your downloads folder so it can delete unlinked "junk" files taking up space.
      "${myConstants.paths.services2TB}/qbittorrent/downloads:/downloads"
    ];
  };
}