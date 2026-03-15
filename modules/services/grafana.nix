{ config, pkgs, myConstants, ... }:

{
  services.grafana = {
    enable = true;
    
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = myConstants.services.grafana.port;
        
        # This makes Grafana aware of its public URL if you use a reverse proxy
        domain = "${myConstants.services.grafana.subdomain}.${myConstants.publicDomain}";
        root_url = "https://${myConstants.services.grafana.subdomain}.${myConstants.publicDomain}";
      };
    };

    # Automatically link Prometheus as the default Data Source!
    provision = {
      enable = true;
      datasources.settings.datasources =[
        {
          name = "Prometheus";
          type = "prometheus";
          # Dynamically point to Prometheus's local port
          url = "http://127.0.0.1:${toString myConstants.services.prometheus.port}";
          isDefault = true;
          access = "proxy";
        }
      ];
    };
  };

  # Open the Grafana port so you can access it directly on your LAN
  networking.firewall.allowedTCPPorts = [ myConstants.services.grafana.port ];
}