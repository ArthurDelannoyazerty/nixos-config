{ config, pkgs, myConstants, ... }:

{
  services.prometheus = {
    enable = true;
    port = myConstants.services.prometheus.port;

    # Keep 2 years of historical data
    retentionTime = "2y"; 

    scrapeConfigs =[
      {
        job_name = "netdata";
        scrape_interval = "30s"; 
        metrics_path = "/api/v1/allmetrics";
        params = {
          format =[ "prometheus" ]; 
        };
        static_configs =[
          {
            targets =[ "127.0.0.1:${toString myConstants.services.netdata.port}" ];
          }
        ];
      }
    ];
  };

  # Automatically manage the 4TB HDD storage directory and symlink it to the state path
  systemd.tmpfiles.rules = [
    # Creates the storage directory on the HDD with correct permissions if it doesn't exist
    "d ${myConstants.paths.services4TB}/prometheus2 0751 prometheus prometheus - -"

    # Creates a symlink pointing the SSD's data folder to the HDD location
    "L+ /var/lib/${config.services.prometheus.stateDir}/data - - - - ${myConstants.paths.services4TB}/prometheus2"
  ];
}