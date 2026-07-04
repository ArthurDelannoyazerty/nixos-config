{ config, pkgs, myConstants, ... }:

let
  envFile = "${myConstants.paths.servicesSSD}/diun/secrets.env";
in
{
  virtualisation.oci-containers.containers.${myConstants.services.diun.containerName} = {
    image = "ghcr.io/crazymax/diun:${myConstants.services.diun.version}";
    
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
      
      /* --- NOTIFICATIONS (Pick ONE and uncomment it) --- */
      # Example uses Gmail, change host and port if you use Outlook, Fastmail, Proton, etc.
      DIUN_NOTIF_MAIL_HOST = "smtp.gmail.com"; 
      DIUN_NOTIF_MAIL_PORT = "587";
      DIUN_NOTIF_MAIL_FROM = "homelab@example.com"; # The email sending the alert
      DIUN_NOTIF_MAIL_TO = "your-actual-email@example.com";   # Where you want to receive it

    };
  };

  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/diun 0700 root root -"
  ];
}