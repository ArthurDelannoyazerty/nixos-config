{ config, pkgs, myConstants, ... }:

{
  # --- COBALT API (download fallback engine for navidrome-importer) ---
  virtualisation.oci-containers.containers.${myConstants.services.cobalt.containerName} = {
    image = "ghcr.io/imputnet/cobalt:${myConstants.services.cobalt.version}";

    # Cobalt listens on 9000 internally -> published as 9009 on the host
    ports = [ "0.0.0.0:${toString myConstants.services.cobalt.port}:9000" ];

    environment = {
      # REQUIRED. This URL is baked into the tunnel links cobalt returns,
      # so it MUST be reachable from the navidrome-importer container:
      # containers -> 172.17.0.1 (docker0 gateway) -> host-published port. 
      API_URL = "http://172.17.0.1:${toString myConstants.services.cobalt.port}";

      # No Turnstile / no API keys: this instance is LAN-only.
      # Edge protection = Caddy privateOnly + Authentik forward_auth;
      # the importer bypasses Caddy entirely over the docker bridge.
      API_AUTH_REQUIRED = "0";

      # Music pipeline only: cap video duration at 2h (default is 3h+)
      DURATION_LIMIT = "7200";

      # Auto-generated poToken & visitor_data for YouTube (big reliability win).
      # Delete this line + the yt-session-generator container below to disable.
      YOUTUBE_SESSION_SERVER = "http://172.17.0.1:${toString myConstants.services.yt-session-generator.port}/";
    };

    extraOptions = [
      "--init"
      "--read-only"                 # official recommended hardening
      "--restart=unless-stopped"
    ];
  };

  # --- YT SESSION GENERATOR (poToken provider, bridge-only) ---
  virtualisation.oci-containers.containers.${myConstants.services.yt-session-generator.containerName} = {
    image = "ghcr.io/imputnet/yt-session-generator:webserver";

    # Bound ONLY to the docker bridge gateway: reachable from containers,
    # invisible to LAN devices and never routed through Caddy.
    ports = [ "172.17.0.1:${toString myConstants.services.yt-session-generator.port}:8080" ];

    extraOptions = [
      "--init"
      "--restart=unless-stopped"
    ];
  };
}