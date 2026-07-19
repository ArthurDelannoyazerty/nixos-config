{ config, pkgs, myConstants, ... }:

let
  # Dedicated, root-owned directory for safe database dumps
  dumpDir = "${myConstants.paths.servicesSSD}/borgmatic-dumps";

  # Define where the temporary SQL dumps will be stored before backup
  authentikDump = "${dumpDir}/authentik_dump.sql";
  immichDump = "${dumpDir}/immich_dump.sql";
  rommDump = "${dumpDir}/romm_dump.sql";
in
{
  # Ensure the backup directory and secret directory exist
  systemd.tmpfiles.rules =[
    "d /var/lib/borgmatic 0700 root root -"
    "d ${myConstants.paths.disk2TB}/backups 0700 root root -"
    "d ${dumpDir} 0700 root root -"
  ];

  systemd.services.borgmatic.serviceConfig.ReadWritePaths =[
    dumpDir
  ];

  services.borgmatic = {
    enable = true;
    
    settings = {

      # The 2TB Drive
      repositories =[
        { path = "${myConstants.paths.disk2TB}/backups/borg-repo"; label = "local-2tb"; }
      ];
      
      # What we are backing up (SSD + 4TB HDD)
      source_directories =[
        myConstants.paths.servicesSSD
        myConstants.paths.services4TB
        
        # backup manga, comics, and music
        "${myConstants.paths.disk4TB}/media"

        "/var/lib/grafana"
        "/var/lib/prometheus2"
        "/var/lib/scrutiny"
        "/var/lib/uptime-kuma"

        # Secrets outside the services folder
        "/var/lib/cloudflared"
      ];

      # EXCLUSIONS: Save space by not backing up massive reproducible files & caches
      exclude_patterns =[
        # Large Media (Easily redownloadable)
        "*/media/anime/*"
        "*/media/movies/*"
        "*/media/series/*"
        
        # System and App Caches
        "*/tmp/*"
        "*/cache/*"
        "*/redis/*"                 # Redis is temporary cache
        "*/loki/chunks/*"           # Loki logs get massive
        "*.backup"                  # Ignore temporary backup files

        # Immich metadatas (Don't backup things Immich can automatically regenerate)
      "*/immich/model-cache/*"
      "*/immich/photos/thumbs/*"
      "*/immich/photos/encoded-video/*"
        
        # Media Server Metadata Caches (Optional, but saves SSD backup space)
        "*/jellyfin/metadata/*"
        "*/jellyfin/transcodes/*"
        
        # Torrent/Usenet Downloads (If you have a scratch/download folder in services)
        "*/qbittorrent/downloads/*"
        "*/sabnzbd/downloads/*"
      ];

      compression = "zstd,3";       # Incredible compression with almost no CPU hit
      encryption_passcommand = "${pkgs.coreutils}/bin/cat /var/lib/borgmatic/passphrase";
      archive_name_format = "homelab-{now}";
      

      # How many backups to keep. It uses deduplication, so this takes very little space
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
      match_archives  = "homelab-*";


      # bit rot check
      checks =[
        { name = "repository"; frequency = "2 weeks"; }
        { name = "archives"; frequency = "4 weeks"; }
      ];

      commands = [
        {
          before = "action";
          when = [ "create" ];
          run =[
            "echo 'Starting Database Dumps...'"
            "${pkgs.docker}/bin/docker exec authentik-db pg_dump -U authentik authentik > ${authentikDump}"
            "${pkgs.docker}/bin/docker exec immich-db pg_dump -U postgres immich > ${immichDump}"
            "${pkgs.docker}/bin/docker exec romm-db sh -c 'mariadb-dump -u root -p\"$MARIADB_ROOT_PASSWORD\" romm' > ${rommDump}"
          ];
        }
        {
          after = "action";
          when =[ "create" ];
          run =[
            "echo 'Backup finished successfully. Cleaning up dumps...'"
            "rm -f ${authentikDump} ${immichDump} ${rommDump}"
          ];
        }
        {
          after = "error";
          run =[
            "echo '🚨 Error during Borgmatic backup! Cleaning up leftover dumps...'"
            "rm -f ${authentikDump} ${immichDump} ${rommDump}"
          ];
        }
      ];

      hooks = {
        uptime_kuma = {
          push_url = "https://uptime-kuma.arthur-lab.com/api/push/HqKUlJ5X2J03UnPKgYB0vviAZfiNZO8O";
        };
      };
    };

  };

  # Schedule the backup to run automatically every night at 3:00 AM
  systemd.timers.borgmatic.timerConfig = {
    OnCalendar = "*-*-* 03:00:00";
    Persistent = true;
  };
}