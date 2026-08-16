{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.navidrome.containerName} = {
    image = "ghcr.io/navidrome/navidrome:${myConstants.services.navidrome.version}";

    ports = [ (myConstants.bind myConstants.services.navidrome.port) ];

    environment = {
      ND_SCANSCHEDULE = "1h";
      ND_LOGLEVEL = "info";
      ND_SESSIONTIMEOUT = "24h";
      ND_BASEURL = "";

      ND_UICOVERARTSIZE = "600";
      ND_COVERARTQUALITY = "100";
      ND_ENABLEWEBPENCODING = "true";

      ND_IMAGECACHESIZE = "1GB";
      ND_TRANSCODINGCACHESIZE = "1GB";

      # --- OIDC / SSO REVERSE PROXY AUTH ---
      # Match the header sent by Authentik's Caddy outpost
      ND_REVERSEPROXYUSERHEADER = "X-Authentik-Username";
      ND_REVERSEPROXYWHITELIST = "0.0.0.0/0";
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/navidrome/data:/data"
      "${myConstants.paths.disk4TB}/media/music:/music:ro"
    ];

    extraOptions = [ 
      "--add-host=host.docker.internal:host-gateway" 
    ];
  };
}