{ config, pkgs, myConstants, ... }:

let
  envFile = "${myConstants.paths.servicesSSD}/diun/secrets.env";
in
{
  virtualisation.oci-containers.containers.${myConstants.services.diun.containerName} = {
    image = "ghcr.io/crazy-max/diun:${myConstants.services.diun.version}";
    
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
    
    environmentFiles = [ envFile ]; 
    
    environment = {
      TZ = "Europe/Paris";
      LOG_LEVEL = "info";
      
      # When to check for updates (Cron syntax). Currently: Every day at 02:00 AM
      DIUN_WATCH_SCHEDULE = "0 2 * * *"; 
      
      DIUN_PROVIDERS_DOCKER = "true";
      DIUN_PROVIDERS_DOCKER_WATCHBYDEFAULT = "true"; # Watch all running containers automatically without needing specific labels
      
      /* --- NOTIFICATIONS --- */
      # Webhook Configuration for n8n 
      DIUN_NOTIF_WEBHOOK_ENDPOINT = "http://${myConstants.dockerSocketProxy}:5678/webhook/diun-in";
      DIUN_NOTIF_WEBHOOK_METHOD = "POST";
      DIUN_NOTIF_WEBHOOK_HEADERS_CONTENT_TYPE = "application/json";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/diun 0700 root root -"
  ];
}