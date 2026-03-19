{ config, pkgs, myConstants, ... }:

{
  services.loki = {
    enable = true;
    
    configuration = {
      server.http_listen_port = myConstants.services.loki.port;
      auth_enabled = false;
      
      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "/var/lib/loki";
      };

      schema_config = {
        configs =[{
          from = "2024-01-01";
          store = "tsdb"; 
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
      };

      storage_config.filesystem.directory = "/var/lib/loki/chunks";

      # Tell Loki to drop data older than 30 days
      limits_config = {
        retention_period = "30d"; 
      };

      # Enable the background worker that actually deletes the files
      compactor = {
        working_directory = "/var/lib/loki/compactor";
        delete_request_store = "filesystem"; 
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
      };
    };
  };
}