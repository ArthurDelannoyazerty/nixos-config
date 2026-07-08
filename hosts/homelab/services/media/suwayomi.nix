{ config, myConstants, ... }:

{
  systemd.tmpfiles.rules =[
    "d ${myConstants.paths.servicesSSD}/suwayomi 0755 1000 1000 -"
    "d ${myConstants.paths.disk4TB}/media/manga/suwayomi 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers."${myConstants.services.suwayomi.containerName}" = {
    image = "ghcr.io/suwayomi/tachidesk:${myConstants.services.suwayomi.version}";

    ports =[ (myConstants.bind myConstants.services.suwayomi.port) ];

    environment = {
      TZ = "Europe/Paris";
      
      WEB_UI_ENABLED = "true";
      DOWNLOAD_AS_CBZ = "true";
    };

    volumes =[
      # App Configuration / DB
      "${myConstants.paths.servicesSSD}/suwayomi:/home/suwayomi/.local/share/Tachidesk"
      # Point downloads directly into your bulk manga folder
      "${myConstants.paths.disk4TB}/media/manga/suwayomi:/home/suwayomi/.local/share/Tachidesk/downloads" 
    ];
  };
}