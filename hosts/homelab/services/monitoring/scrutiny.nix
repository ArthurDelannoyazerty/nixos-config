{ config, pkgs, myConstants, ... }: 

{
  # Install smartmontools so Scrutiny can read the disk health sensors
  environment.systemPackages = with pkgs; [ smartmontools ];

  services.scrutiny = {
    enable = true;
    
    # Enable the collector which scans your disks every 15 minutes
    collector.enable = true;
    
    settings = {
      web = {
        listen = {
          port = myConstants.services.scrutiny.port;
          host = "0.0.0.0";
        };
      };
    };
  };
}