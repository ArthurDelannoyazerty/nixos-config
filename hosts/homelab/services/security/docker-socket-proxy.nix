{ pkgs, ... }:
{
  virtualisation.oci-containers.containers.socket-proxy = {
    image = "tecnativa/docker-socket-proxy";
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ]; # Read-only mount
    environment = {
      CONTAINERS = "1"; # Allow reading containers
      IMAGES     = "1"; # Allow reading images (for whats up docker)
      EVENTS     = "1"; # Allow reading docker event stream
      INFO       = "1"; # Allow reading docker system info
      NETWORKS   = "0";
      VOLUMES    = "0";
      POST       = "0"; # CRITICAL: Deny any capability to create/destroy containers
    };
  };
}