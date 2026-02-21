{ config, pkgs, myConstants, ... }:

{
  services.forgejo = {
    enable = true;
    stateDir = "/mnt/storage/services/forgejo"; # Put Git repos on the big drive
    
    settings = {
      server = {
        DOMAIN = "${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}";
        ROOT_URL = "https://${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}/";
        HTTP_PORT = myConstants.services.forgejo.port;
      };
      # Enable mirroring features
      mirror = {
        ENABLED = true;
        DEFAULT_INTERVAL = "8h";
      };
      # Allow Authentik SSO to create accounts automatically
      service.ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
    };
  };
}