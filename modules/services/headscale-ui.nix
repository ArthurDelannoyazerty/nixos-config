{ config, pkgs, myConstants, ... }:
{
  virtualisation.oci-containers.containers.headscale-ui = {
    image = "ghcr.io/gurucomputing/headscale-ui:${myConstants.services.headscale-ui.version}";
    ports = [ "${toString myConstants.services.headscale-ui.port}:80" ]; # Expose on local 9443
    environment = {
      HTTP_PORT = "80";
      # This connects the UI to your Headscale instance
      HEADSCALE_URL = "https://${myConstants.services.headscale.subdomain}.${myConstants.domain}";
    };
  };

  # Add this to your Caddy configuration (server.nix or caddy.nix)
  # http://headscale-ui.home.arpa -> internal 9443
}