{ config, pkgs, myConstants, ... }:

let
  # Define where the temporary SQL dumps will be stored before backup
  authentikDump = "${myConstants.paths.servicesSSD}/authentik/authentik_dump.sql";
  immichDump = "${myConstants.paths.servicesSSD}/immich/immich_dump.sql";
  rommDump = "${myConstants.paths.servicesSSD}/romm/romm_dump.sql";
in
{
  # Ensure the backup directory and secret directory exist
  systemd.tmpfiles.rules =[
    "d /var/lib/borgmatic 0700 root root -"
    "d ${myConstants.paths.disk2TB}/backups 0700 root root -"
  ];

  services.borgmatic = {
    enable = true;
    
    settings = {
      location = {
        # The 2TB Drive
        repositories =[
          { path = "${myConstants.paths.disk2TB}/backups/borg-repo"; label = "local-2tb"; }
        ];
        
        # What we are backing up (SSD + 4TB HDD)
        source_directories =[
          myConstants.paths.servicesSSD
          myConstants.paths.services4TB

          "/var/lib/grafana"
          "/var/lib/prometheus2"
          "/var/lib/scrutiny"
          "/var/lib/uptime-kuma"

          # Secrets outside the services folder
          "/var/lib/cloudflared"
        ];

        # EXCLUSIONS: Save space by not backing up caches and logs
        exclude_patterns =[
          "*/tmp/*"
          "*/cache/*"
          "*/redis/*"                 # Redis is temporary cache, no need to back it up
          "*/loki/chunks/*"           # Loki logs get massive
          "*/immich/model-cache/*"    # ML models will just re-download if lost
          "*.backup"                  # Ignore temporary backup files
        ];
      };

      storage = {
        compression = "zstd,3";       # Incredible compression with almost no CPU hit
        encryption_passcommand = "${pkgs.coreutils}/bin/cat /var/lib/borgmatic/passphrase";
        archive_name_format = "homelab-{now}";
      };

      retention = {
        # How many backups to keep. It uses deduplication, so this takes very little space
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;
        prefix = "homelab-";
      };

      # bit rot check
      consistency = {
        checks =[
          { name = "repository"; frequency = "2 weeks"; }
          { name = "archives"; frequency = "4 weeks"; }
        ];
      };

      hooks = {
        # Safely dump active databases to static .sql files BEFORE the backup starts
        before_backup =[
          "echo 'Starting Database Dumps...'"
          "${pkgs.docker}/bin/docker exec authentik-db pg_dump -U authentik authentik > ${authentikDump}"
          "${pkgs.docker}/bin/docker exec immich-db pg_dump -U postgres immich > ${immichDump}"
          # We execute sh -c so the MariaDB container uses its internal environment variable for the root password
          "${pkgs.docker}/bin/docker exec romm-db sh -c 'mariadb-dump -u root -p\"$MARIADB_ROOT_PASSWORD\" romm' > ${rommDump}"
        ];

        # Clean up the dumps AFTER the backup finishes so they don't waste SSD space
        after_backup =[
          "echo 'Backup finished successfully. Cleaning up dumps...'"
          "rm -f ${authentikDump} ${immichDump} ${rommDump}"
        ];

        on_error =[
          "echo '🚨 Error during Borgmatic backup!'"
        ];
      };
    };
  };

  # Schedule the backup to run automatically every night at 3:00 AM
  systemd.timers.borgmatic.timerConfig = {
    OnCalendar = "*-*-* 03:00:00";
    Persistent = true;
  };
}