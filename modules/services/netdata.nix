{ config, pkgs, myConstants, ... }:

{
  services.netdata = {
    enable = true;

    # STEP 1: Override the package to include the Modern Dashboard (unfree)
    package = pkgs.netdata.override { 
      withCloudUi = true; 
    };


    config = {
      global = {
        # STEP 2: Tell Netdata exactly where the web files are in the Nix store
        "web files directory" = "${config.services.netdata.package}/share/netdata/web";
        
        "update every" = 1; # Back to 1s for real-time feel
        "memory mode" = "dbengine";
        "dbengine disk space" = 256;
      };

      web = {
        "bind to" = "127.0.0.1";
        # Allow access from your local machine and your Caddy/Authentik setup
        "allow connections from" = "localhost 127.0.0.1 ::1 172.17.*";
        "allow dashboard from" = "localhost 127.0.0.1 ::1 172.17.*";
      };

      cloud = {
        "enabled" = "no";
      };
      analytics = {
        "enabled" = "no";
      };
      ml = {
        "enabled" = "no";
      };
      
      "plugin:freeipmi" = {
       "enabled" = "no";
      };
    };
  };

  # STEP 3: Security & Sandbox Fix
  # Systemd on NixOS sandboxes Netdata. We must allow it to read its own store path.
  systemd.services.netdata.serviceConfig = {
    RuntimeDirectory = "netdata";
    RuntimeDirectoryMode = "0750";
    ProtectSystem = "full";
    # This allows the netdata process to see the web files in /nix/store
    BindReadOnlyPaths = [ "/nix/store" ];
  };
}