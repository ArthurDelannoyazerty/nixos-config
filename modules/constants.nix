rec {
  # Internal domain for services
  domain = "home.arpa";

  # Public domain
  publicDomain = "arthur-lab.com"; 

  dockerSocketProxy = "172.17.0.1";
  
  # Usage: bind 8501 -> "172.17.0.1:8501:8501"
  bind = port: "0.0.0.0:${toString port}:${toString port}";

  # THE REGISTRY
  services = {
    authentik = {
      port = 9000;
      subdomain = "authentik";
      version = "2024.12.3";
      containerName = "authentik-server";
    };
    authentik-db = {
      port = 5432;
      version = "16-alpine";
      containerName = "authentik-db";
    };
    authentik-redis = {
      port = 6379;
      version = "alpine";
      containerName = "authentik-redis";
    };
    authentik-worker = {
      port = 9000;
      version = "2024.12.3";
      containerName = "authentik-worker";
    };
    bazarr = { 
      port = 6767; 
      subdomain = "bazarr"; 
    };
    filebrowser-quantum = {
      port = 8088;
      subdomain = "filebrowser-quantum";
      version = "1.2-stable";
      containerName = "filebrowser-quantum";
    };
    filebrowser = {
      port = 8081;
      subdomain = "filebrowser";
    };
    forgejo = {
      port = 8083;
      subdomain = "forgejo";
    };
    glances = {
      port = 61208;
      subdomain = "glances";
      version = "4.4.1-full";
    };
    grafana = {
      port = 3002;
      subdomain = "grafana";
    };
    headscale = {
      port = 8080;
      subdomain = "headscale";
    };
    headscale-ui = {
      port = 9443;
      subdomain = "headscale-ui";
      version = "latest";
    };
    homepage = {
      port = 3000;
      subdomain = "homepage";
      version = "v1.11.0";
      containerName = "homepage";
    };
    immich = {
      port = 2283;
      subdomain = "immich";
      version = "v2.6.1";
      containerName = "immich-server";
    };
    immich-db = {
      port = 5433;
      version = "14-vectorchord0.4.3-pgvectors0.2.0";
      containerName = "immich-db";
    };
    immich-redis = {
      port = 999999999; # Not exposed to host, only for internal communication
      version = "6.2-alpine";
      containerName = "immich-redis";
    };
    immich-machine-learning = {
      port = 2283;
      version = "v2.6.1";
      containerName = "immich-machine-learning";
    };
    jellyfin = { 
      port = 8096; 
      subdomain = "jellyfin"; 
    };
    jellyseerr = { 
      port = 5055; 
      subdomain = "requests"; 
    };
    lidarr = { 
      port = 8686; 
      subdomain = "lidarr"; 
    };
    lldap = {
      port = 3890;
      html-port = 17171;
      subdomain = "lldap";
    };
    finance = {
      port = 8501;
      subdomain = "finance";
    };
    loki = {
      port = 3100;
    };
    n8n = {
      port = 5678;
      subdomain = "n8n";
      version = "2.11.3";
      containerName = "n8n";
    };
    netdata = {
      port = 19999;
      subdomain = "netdata";
    };
    nextcloud = {
      port = 8087;
      subdomain = "nextcloud"; 
      version = "33-apache";
    };
    paperless-ngx = {
      port = 8000;
      subdomain = "paperless-ngx";
      version = "latest";
    };
    power-monitor = {
      port = 9100;
    };
    prometheus = {
      port = 9090;
    };
    promtail = {
      port = 9080;
    };
    prowlarr = { 
      port = 9696; 
      subdomain = "prowlarr"; 
    };
    radarr = { 
      port = 7878; 
      subdomain = "radarr";
    };
    romm = {
      port = 8085;
      subdomain = "romm";
      version = "latest";
      containerName = "romm";
    };
    romm-db = {
      port = 999999997; # Not exposed to host, only for internal communication
      version = "11";
      containerName = "romm-db";
    };
    romm-redis = {
      port = 999999998; # Not exposed to host, only for internal communication
      version = "7-alpine";
      containerName = "romm-redis";
    };
    sabnzbd = { 
      port = 8080; 
      subdomain = "sabnzbd"; 
    };
    scrutiny = {
      port = 8082;
      subdomain = "scrutiny";
    };
    sonarr = { 
      port = 8989; 
      subdomain = "sonarr"; 
    };
    uptime-kuma = {
      port = 3001;
      subdomain = "uptime-kuma";
    };
    vikunja = {
      port = 3456;
      subdomain = "vikunja";
      version = "2.2.2";
    };
  };
}