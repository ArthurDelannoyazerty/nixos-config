# /modules/services/vikunja/vikunja.nix
{ config, pkgs, ... }:

let
  vikunjaPort = 3456;
  vikunjaVersion = 1.0.0-rc3
in
{
  # 1. Open Firewall
  networking.firewall.allowedTCPPorts = [ vikunjaPort ];

  # 2. Container Configuration
  virtualisation.oci-containers.containers.vikunja = {
    image = "vikunja/vikunja:${toString vikunjaVersion}";
    ports = [ "${toString vikunjaPort}:3456" ];

    environmentFiles = [
      "/var/lib/vikunja/secret.env"
    ];
    
    environment = {
      # The URL is required for the API to function correctly
      VIKUNJA_SERVICE_PUBLICURL = "http://${config.networking.hostName}:${toString vikunjaPort}/";
      # Use SQLite for a simple single-container setup
      VIKUNJA_DATABASE_TYPE = "sqlite"; 
    };

    volumes = [
      # Persist data on the host
      "/var/lib/vikunja/files:/app/vikunja/files"
      "/var/lib/vikunja/db:/app/vikunja/db"
    ];
  };

  # 3. Ensure data directories exist on host
  systemd.tmpfiles.rules = [
    "d /var/lib/vikunja/files 0755 root root -"
    "d /var/lib/vikunja/db 0755 root root -"
  ];
}