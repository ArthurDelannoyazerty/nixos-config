{ config, myConstants, ... }:

{
  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/jellyfin 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers."${myConstants.services.jellyfin.containerName}" = {
    image = "lscr.io/linuxserver/jellyfin:${myConstants.services.jellyfin.version}";

    ports = [ 
      (myConstants.bind myConstants.services.jellyfin.port) 
      
      # Optional but recommended by official docs: 
      # Allows clients on your local network to auto-discover the server
      "7359:7359/udp" 
      
      # "1900:1900/udp" # Uncomment only if you specifically use DLNA
    ];

    environment = { 
      PUID = "1000"; 
      PGID = "1000"; 
      TZ = "Europe/Paris"; 
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/jellyfin:/config"
      "${myConstants.paths.disk4TB}/media:/data"
    ];

    # CRITICAL FOR INTEL CPUs: Pass the integrated GPU to Jellyfin for Hardware Transcoding
    extraOptions = [
      "--device=/dev/dri:/dev/dri"
    ];
  };
}