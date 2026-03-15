{ config, pkgs, myConstants, ... }:

{
  services.prometheus = {
    enable = true;
    port = myConstants.services.prometheus.port;

    # Keep 30 days of historical data
    retentionTime = "2y"; 

    scrapeConfigs =[
      {
        job_name = "netdata";
        scrape_interval = "5s"; 
        metrics_path = "/api/v1/allmetrics";
        params = {
          # Ask Netdata to format the output for Prometheus
          format =[ "prometheus" ]; 
        };
        static_configs =[
          {
            # Dynamically pull the port from constants.nix
            targets =[ "127.0.0.1:${toString myConstants.services.netdata.port}" ];
          }
        ];
      }
    ];
  };
}