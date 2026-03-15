# /modules/services/grafana.nix
{ config, pkgs, myConstants, ... }:

{
  services.grafana = {
    enable = true;
    
    settings = {
      server = {
        # Bind to localhost so it cannot be reached from the outside natively
        http_addr = "0.0.0.0";
        http_port = myConstants.services.grafana.port;
        
        domain = "${myConstants.services.grafana.subdomain}.${myConstants.publicDomain}";
        root_url = "https://${myConstants.services.grafana.subdomain}.${myConstants.publicDomain}/";
      };

      # SEAMLESS AUTHENTIK SSO
      # Reads the headers injected by your Caddy 'authentikMiddleware'
      "auth.proxy" = {
        enabled = true;
        header_name = "X-Authentik-Username";
        header_property = "username";
        auto_sign_up = true;
      };

      users = {
        auto_assign_org_role = "Admin";
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources =[
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString myConstants.services.prometheus.port}";
          isDefault = true;
          access = "proxy";
        }
      ];
    };
  };

}