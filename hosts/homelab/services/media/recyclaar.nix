{ config, myConstants, ... }:

{
  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/recyclarr 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers."${myConstants.services.recyclarr.containerName}" = {
    image = "ghcr.io/recyclarr/recyclarr:${myConstants.services.recyclarr.version}";

    environment = {
      TZ = "Europe/Paris";
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/recyclarr:/config"
    ];

    user = "1000:1000";
  };
}