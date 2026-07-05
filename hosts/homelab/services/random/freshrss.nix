{ config, pkgs, myConstants, ... }:

let
  envFile = "${myConstants.paths.servicesSSD}/freshrss/secrets.env";
in
{
  virtualisation.oci-containers.containers.${myConstants.services.freshrss.containerName} = {
    image = "freshrss/freshrss:${myConstants.services.freshrss.version}";
    
    ports = [ "0.0.0.0:${toString myConstants.services.freshrss.port}:80" ];
    
    environment = {
      TZ = "Europe/Paris";
      CRON_MIN = "*/15";
      TRUSTED_PROXY = "172.16.0.0/12 192.168.0.0/16 10.0.0.0/8"; 
    };

    environmentFiles = [ envFile ];

    volumes = [
      "${myConstants.paths.servicesSSD}/freshrss/data:/var/www/FreshRSS/data"
      "${myConstants.paths.servicesSSD}/freshrss/extensions:/var/www/FreshRSS/extensions"
    ];

    extraOptions = [ 
      "--add-host=host.docker.internal:host-gateway" 
    ];
  };
}