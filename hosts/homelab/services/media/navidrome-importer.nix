{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.navidrome-importer.containerName} = {
    image = "ghcr.io/arthurdelannoyazerty/yt-navidrome:${myConstants.services.navidrome-importer.version}";

    # App listens on 8008 inside the container.
    ports = [
      "0.0.0.0:${toString myConstants.services.navidrome-importer.port}:8008"
    ];

    environment = {
      # Persistent application state.
      # Contains ingestor.sqlite, per-user beets DBs, staging files,
      # downloader runtimes, updater state, etc.
      INGESTOR_STATE_DIR = "/data/state";

      # Navidrome music library.
      NAVIDROME_LIB_DIR = "/data/library";

      # Empty = preserve yt-dlp's maintained/default player-client behavior.
      YT_PLAYER_CLIENTS = "";

      # Periodically re-sync monitored playlists.
      # 0 disables source auto-sync.
      SYNC_INTERVAL_HOURS = "6";

      # Application-side YouTube API budget.
      YT_DAILY_BUDGET = "9000";

      # "source" preserves playlist order.
      # Alternative: "discovery".
      PLAYLIST_ORDER = "source";

      # Nightly yt-dlp runtime update.
      # This does NOT restart FastAPI.
      YTDLP_UPDATE_ENABLED = "true";
      YTDLP_UPDATE_TIME = "04:00";
      TZ = "Europe/Paris";
    };

    # Keep secrets and local downloader settings outside the Nix store.
    environmentFiles = [
      "/var/lib/services/navidrome-importer/env"
    ];

    volumes = [
      # Persistent application state:
      # /data/state/ingestor.sqlite
      # /data/state/beets/<user>/library.db
      # /data/state/staging/
      # /data/state/runtimes/
      "${myConstants.paths.servicesSSD}/navidrome-importer:/data"

      # Downloaded/tagged music goes directly into Navidrome's library.
      # This child bind mount overrides /data/library from the /data parent mount.
      "${myConstants.paths.disk4TB}/media/music:/data/library"
    ];
  };
}