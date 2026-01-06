# /modules/services/caddy/caddy.nix
{ config, pkgs, myConstants, ... }:

{
  services.caddy = {
    enable = true;
    virtualHosts = {
      
      # Homepage
      "http://${myConstants.services.homepage.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString myConstants.services.homepage.port}
        '';
      };

      # Finance
      "http://${myConstants.services.finance.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          # In a real setup, add Authelia middleware here
          reverse_proxy 127.0.0.1:${toString myConstants.services.finance.port}
        '';
      };

      # Glances
      "http://${myConstants.services.glances.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          # Basic Auth: User "arthur", Password "password" (hashed)
          # Use `caddy hash-password` to generate the hash
          basicauth / {
            arthur $2a$14$....hash_goes_here...
          }
          reverse_proxy 127.0.0.1:${toString myConstants.services.glances.port}
        '';
      };
      
      # LLDAP
      "http://${myConstants.services.lldap.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
             reverse_proxy 127.0.0.1:${toString myConstants.services.lldap.html-port}
        '';
      };

    };
  };

}