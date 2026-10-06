{ config, pkgs, myConstants, ... }:

{
  # --- COBALT WEB UI ---
  virtualisation.oci-containers.containers.${myConstants.services.cobalt-web.containerName} = {
    image = "ghcr.io/spotdemo4/cobalt-web:${myConstants.services.cobalt-web.version}";
    ports = [ "0.0.0.0:${toString myConstants.services.cobalt-web.port}:8787" ];
    environment = {
      # Must have trailing slash
      WEB_DEFAULT_API = "https://${myConstants.services.cobalt-api.subdomain}.${myConstants.publicDomain}/";
    };
    extraOptions = [ "--init" ];
  };

  # --- COBALT API ---
  virtualisation.oci-containers.containers.${myConstants.services.cobalt-api.containerName} = {
    image = "ghcr.io/imputnet/cobalt:${myConstants.services.cobalt-api.version}";

    ports = [ "0.0.0.0:${toString myConstants.services.cobalt-api.port}:9000" ];

    dependsOn = [ myConstants.services.yt-session-generator.containerName ];

    environment = {
      # REQUIRED: URL baked into the tunnel download links for browsers
      API_URL = "https://${myConstants.services.cobalt-api.subdomain}.${myConstants.publicDomain}";

      API_AUTH_REQUIRED = "0";

      # YOUTUBE_SESSION_SERVER = "http://172.17.0.1:${toString myConstants.services.yt-session-generator.port}/";

      CUSTOM_INNERTUBE_CLIENT = "ANDROID_VR";
    };

    extraOptions = [
      "--init"
      "--read-only"
      "--link=${myConstants.services.yt-session-generator.containerName}:${myConstants.services.yt-session-generator.containerName}"
    ];
  };


  # --- BGUTIL PO-TOKEN GENERATOR (Replaces abandoned yt-session-generator) ---
  virtualisation.oci-containers.containers.${myConstants.services.yt-session-generator.containerName} = {
    image = "brainicism/bgutil-ytdlp-pot-provider:${myConstants.services.yt-session-generator.version}";

    # Bind strictly to the Docker bridge gateway
    ports = [ "172.17.0.1:${toString myConstants.services.yt-session-generator.port}:4416" ];

    extraOptions = [
      "--init"
    ];
  };

}