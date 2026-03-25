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
    vikunja = {
      port = 3456;
      subdomain = "vikunja";
      version = "2.2.2";
    };
    finance = {
      port = 8501;
      subdomain = "finance";
    };
    homepage = {
      port = 3000;
      subdomain = "homepage";
      version = "v1.11.0";
    };
    glances = {
      port = 61208;
      subdomain = "glances";
      version = "4.4.1-full";
    };
    lldap = {
      port = 3890;
      html-port = 17171;
      subdomain = "lldap";
    };
    netdata = {
      port = 19999;
      subdomain = "netdata";
    };
    power-monitor = {
      port = 9100;
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
    filebrowser = {
      port = 8081;
      subdomain = "filebrowser";
    };
    scrutiny = {
      port = 8082;
      subdomain = "scrutiny";
    };
    uptime-kuma = {
      port = 3001;
      subdomain = "uptime-kuma";
    };
    forgejo = {
      port = 8083;
      subdomain = "forgejo";
    };
    immich = {
      port = 2283;
      subdomain = "immich";
      version = "v2.6.1";
    };
    n8n = {
      port = 5678;
      subdomain = "n8n";
      version = "2.11.3";
    };
    romm = {
      port = 8085;
      subdomain = "romm";
      version = "latest";
    };
    prometheus = {
      port = 9090;
    };
    grafana = {
      port = 3002;
      subdomain = "grafana";
    };
    jellyfin = { 
      port = 8096; 
      subdomain = "jellyfin"; 
    };
    jellyseerr = { 
      port = 5055; 
      subdomain = "requests"; 
    };
    sonarr = { 
      port = 8989; 
      subdomain = "sonarr"; 
    };
    radarr = { 
      port = 7878; 
      subdomain = "radarr";
    };
    lidarr = { 
      port = 8686; 
      subdomain = "lidarr"; 
    };
    prowlarr = { 
      port = 9696; 
      subdomain = "prowlarr"; 
    };
    bazarr = { 
      port = 6767; 
      subdomain = "bazarr"; 
    };
    sabnzbd = { 
      port = 8080; 
      subdomain = "sabnzbd"; 
    };
    loki = {
      port = 3100;
    };
    promtail = {
      port = 9080;
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
    filebrowser-quantum = {
      port = 8088;
      subdomain = "filebrowser-quantum";
      version = "1.2-stable";
      containerName = "filebrowser-quantum";
    };
  };
}