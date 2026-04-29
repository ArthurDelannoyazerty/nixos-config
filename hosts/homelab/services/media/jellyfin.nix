{ config, pkgs, myConstants, ... }:

{

  services.jellyfin = {
    enable = true;
  };

  # For hardware transcoding (Intel/AMD)
  environment.systemPackages =[ pkgs.jellyfin-ffmpeg pkgs.jellyfin-web pkgs.jellyfin-ui-desktop ];
}