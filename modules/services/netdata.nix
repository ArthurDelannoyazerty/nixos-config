{ config, pkgs, myConstants, ... }:

{
  services.netdata = {
    enable = true;
    package = pkgs.netdata; # Uses the official Nix package
    
    # We explicitly set the port to match your constants
    config = {
      global = {
        "default port" = myConstants.services.netdata.port;
        "history" = 3600; # Keep 1 hour of history in RAM (adjust as needed)
        "memory mode" = "dbengine"; # Save history to disk
        "page cache size" = 32;
        "dbengine disk space" = 256;
      };
      
      # Disable Cloud / Sign-in
      cloud = {
        "enabled" = "no";
      };
      
      # Allow access from Localhost (Caddy) and Docker Subnet (Homepage)
      web = {
        "allow connections from" = "localhost 172.17.0.* 127.0.0.1";
        "bind to" = "0.0.0.0"; # Listen on all interfaces so Docker containers can see it
      };
    };
  };
}