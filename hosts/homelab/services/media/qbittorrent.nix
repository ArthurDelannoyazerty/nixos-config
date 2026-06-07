{ config, myConstants, ... }:

{
  # Pre-create the directories to ensure UID 1000 owns them
  systemd.tmpfiles.rules =[
    "d ${myConstants.paths.servicesSSD}/qbittorrent 0755 1000 1000 -"
    "d ${myConstants.paths.services2TB}/qbittorrent/downloads 0755 1000 1000 -"
  ];

  # AUTOMATIC RECOVERY: Delete stale lockfiles right before Docker starts the container
  systemd.services."docker-${myConstants.services.qbittorrent.containerName}" = {
    preStart = ''
      rm -f ${myConstants.paths.servicesSSD}/qbittorrent/qBittorrent/lockfile
      rm -f ${myConstants.paths.servicesSSD}/qbittorrent/qBittorrent/ipc-socket
    '';
  };

  virtualisation.oci-containers.containers."${myConstants.services.qbittorrent.containerName}" = {
    image = "lscr.io/linuxserver/qbittorrent:${myConstants.services.qbittorrent.version}";

    ports =[ 
      # Web UI Port (8095)
      (myConstants.bind myConstants.services.qbittorrent.port) 
      # Torrent Peer Connections (Crucial for downloading/seeding)
      "6881:6881"
      "6881:6881/udp"
    ];

    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "Europe/Paris";
      WEBUI_PORT = toString myConstants.services.qbittorrent.port;
    };

    volumes =[
      "${myConstants.paths.servicesSSD}/qbittorrent:/config"
      # The folder where Torrents will actually be downloaded
      "${myConstants.paths.services2TB}/qbittorrent/downloads:/downloads" 
    ];
  };
}