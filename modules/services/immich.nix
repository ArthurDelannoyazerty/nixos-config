{ config, pkgs, myConstants, ... }:

{
  services.immich = {
    enable = true;
    
    # Network
    host = "0.0.0.0";
    port = myConstants.services.immich.port;

    # for oidc client secret mainly
    secretsFile = "/var/lib/secrets/immich-secrets.json";
    
    # 1. STORAGE: Put photos on the big HDD
    mediaLocation = "/mnt/storage/immich";
    
    # 2. MACHINE LEARNING
    machine-learning = {
      enable = true;
    };

    # 3. SETTINGS
    settings = {
      server = {
        externalDomain = "https://${myConstants.services.immich.subdomain}.${myConstants.publicDomain}";
      };
      
      # 4. HARDWARE ACCELERATION (Transcoding)
      ffmpeg.transcoding.accel = "qs"; # Use 'nvenc' if you have Nvidia, 'vaapi' generic
      
      # 5. OAUTH (Authentik)
      oauth = {
        enabled = true;
        issuerUrl = "https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/application/o/immich/";
        clientId = "6ZmUPvuIS0lTprsxXWHVkq1Uy8wj0Qt3ovMStrof";
        mobileRedirectUri = "app.immich:///oauth-callback";
        buttonText = "Login with Authentik";
        autoRegister = true;
      };
    };
  };
  
  # Allow Immich to use the Intel GPU for transcoding videos
  hardware.graphics.enable = true;
  users.users.immich.extraGroups = [ "video" "render" ];
}