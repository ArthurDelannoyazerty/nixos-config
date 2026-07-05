{ config, pkgs, myConstants, ... }:

let
  envFile = "${myConstants.paths.servicesSSD}/freshrss/secrets.env";
in
{
  virtualisation.oci-containers.containers.${myConstants.services.freshrss.containerName} = {
    image = "lscr.io/linuxserver/freshrss:${myConstants.services.freshrss.version}";
    ports = [ (myConstants.bind myConstants.services.freshrss.port) ];
    
    environment = {
      PUID = "1000";
      PGID = "1000";
      TZ = "Europe/Paris";
    };

    # This file will contain your Authentik OIDC configuration
    # Example contents:
    # OIDC_ENABLED=1
    # OIDC_CLIENT_ID=your-client-id
    # OIDC_CLIENT_SECRET=your-client-secret
    # OIDC_PROVIDER_METADATA_URL=https://authentik.arthur-lab.com/application/o/freshrss/.well-known/openid-configuration
    environmentFiles = [ envFile ];

    volumes = [
      "${myConstants.paths.servicesSSD}/freshrss/config:/config"
    ];

    extraOptions = [ 
      "--add-host=host.docker.internal:host-gateway" 
    ];
  };
}