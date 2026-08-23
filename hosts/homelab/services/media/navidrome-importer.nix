{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.navidrome-importer.containerName} = {
    image = "ghcr.io/arthurdelannoyazerty/yt-navidrome:${myConstants.services.navidrome-importer.version}";

    # App listens on 8008 inside the image -> exposed as 8009 on the host
    ports = [ "0.0.0.0:${toString myConstants.services.navidrome-importer.port}:8008" ];

    # Explicit -e flags WIN over environmentFiles (--env-file), so these
    # guarantee sane in-container paths even if the env file still has
    # old relative "./navidrome_library" lines from the laptop days.
    environment = {
      NAVIDROME_LIB_DIR = "/data/library";
      LIBRARY_DB = "/data/library.db";
      YT_PLAYER_CLIENTS = "";          # empty = yt-dlp maintained defaults
      COBALT_API_URL = "http://172.17.0.1:${toString myConstants.services.cobalt.port}";
      MAX_CONCURRENT_TRACKS = "3";
      SYNC_INTERVAL_HOURS = "6";       # auto-sync every 6h
    };

    # Secrets (ACOUSTID_API_KEY, YT_API_KEY, SPOTIFY_*, DOWNLOAD_SLEEP_*, ...)
    environmentFiles = [
      "/var/lib/services/navidrome-importer/env"
    ];

    volumes = [
      # DB lives here (library.db + WAL files)
      "${myConstants.paths.servicesSSD}/navidrome-importer:/data"

      # Downloaded music lands straight into Navidrome's library.
      # Child mount wins over the parent /data mount.
      "${myConstants.paths.disk4TB}/media/music:/data/library"
    ];

  };
}