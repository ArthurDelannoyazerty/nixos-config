{ pkgs, ... }:
{
  virtualisation.oci-containers.containers.socket-proxy = {
    image = "tecnativa/docker-socket-proxy";
    ports = [ "2375:2375" ];
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ]; # Read-only mount
    environment = {
      CONTAINERS = "1"; # Allow listing containers
      images = "0";     # Deny listing images
      networks = "0";
      volumes = "0";
      POST = "0";       # CRITICAL: Deny any capability to create/destroy containers
    };
  };
}