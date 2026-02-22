{ config, pkgs, myConstants, ... }:

{
  services.forgejo = {
    enable = true;
    stateDir = "/mnt/storage/services/forgejo"; 
    
    settings = {
      server = {
        DOMAIN = "${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}";
        ROOT_URL = "https://${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}/";
        HTTP_PORT = myConstants.services.forgejo.port;
      };
      mirror = {
        ENABLED = true;
        DEFAULT_INTERVAL = "8h";
      };
      
      service = {
        ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
        ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = true;
        ENABLE_REVERSE_PROXY_EMAIL = true;
      };
      security = {
        # Tell Forgejo exactly which headers Authentik is sending
        REVERSE_PROXY_AUTHENTICATION_USER = "X-Authentik-Username";
        REVERSE_PROXY_AUTHENTICATION_EMAIL = "X-Authentik-Email";
        # Trust Caddy (localhost) to send these headers securely
        REVERSE_PROXY_TRUSTED_PROXIES = "127.0.0.1/32, ::1/128";
      };
    };
  };
}