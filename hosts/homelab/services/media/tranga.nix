{ config, myConstants, pkgs, ... }:

let
  trangaApiUnit =
    "${config.virtualisation.oci-containers.backend}-${myConstants.services.tranga-api.containerName}.service";

  trangaQueueWatch = pkgs.writeShellApplication {
    name = "tranga-queue-watch";

    runtimeInputs = with pkgs; [
      coreutils
      curl
      gawk
      jq
      util-linux
    ];

    text = ''
      API="''${TRANGA_API:-http://127.0.0.1:6531}"
      STATE_DIR="''${TRANGA_STATE_DIR:-/var/lib/tranga-queue-watch}"
      ALERT_AFTER="''${TRANGA_ALERT_AFTER:-3}"
      NTFY_URL="''${TRANGA_NTFY_URL:-}"
      PAGE_SIZE="''${TRANGA_PAGE_SIZE:-100000}"
      API="''${API%/}"

      if ! [[ "$ALERT_AFTER" =~ ^[1-9][0-9]*$ ]]; then
        echo "TRANGA_ALERT_AFTER must be a positive integer" >&2
        exit 2
      fi

      mkdir -p "$STATE_DIR"

      signature_file="$STATE_DIR/signature"
      count_file="$STATE_DIR/count"
      alerted_file="$STATE_DIR/alerted"
      report_file="$STATE_DIR/latest-report.txt"

      pending_file="$(mktemp)"
      formatted_file="$(mktemp)"

      trap 'rm -f "$pending_file" "$formatted_file"' EXIT

      mangas="$(curl -fsS "$API/v2/Manga")"

      if ! jq -e 'type == "array"' >/dev/null <<< "$mangas"; then
        echo "Unexpected response from $API/v2/Manga" >&2
        exit 1
      fi

      while IFS=$'\t' read -r manga_id manga_name; do
        [[ -n "$manga_id" ]] || continue

        chapters="$(
          curl -fsS -X POST \
            "$API/v2/Chapters/Manga/$manga_id?page=1&pageSize=$PAGE_SIZE" \
            -H 'Content-Type: application/json' \
            -d '{}'
        )"

        if ! jq -e '.data | type == "array"' >/dev/null <<< "$chapters"; then
          echo "Unexpected chapter response for $manga_name ($manga_id)" >&2
          exit 1
        fi

        # Create one row per requested chapter-source association.
        # This corresponds more closely to Tranga's actual scheduler queue.
        jq -r \
          --arg manga "$manga_name" \
          --arg manga_id "$manga_id" '
            (.data // [])[]
            | select(.downloaded != true)
            | . as $chapter
            | .mangaConnectorIds[]?
            | select(.useForDownload == true)
            | [
                $manga,
                $manga_id,
                ("Ch." + ($chapter.chapterNumber // "?")),
                ($chapter.title // ""),
                .mangaConnectorName,
                $chapter.key,
                .key
              ]
            | @tsv
          ' <<< "$chapters" >> "$pending_file"

      done < <(
        jq -r '.[] | [.key, .name] | @tsv' <<< "$mangas"
      )

      sort -u "$pending_file" -o "$pending_file"
      pending_count="$(wc -l < "$pending_file")"

      {
        echo "Tranga requested, undownloaded chapter-source links"
        echo "Generated: $(date --iso-8601=seconds)"
        echo "Count: $pending_count"
        echo

        {
          printf \
            'MANGA\tMANGA_ID\tCHAPTER\tTITLE\tSOURCE\tCHAPTER_ID\tCONNECTOR_ID\n'
          cat "$pending_file"
        } | column -s $'\t' -t
      } > "$formatted_file"

      mv "$formatted_file" "$report_file"

      if (( pending_count == 0 )); then
        rm -f \
          "$signature_file" \
          "$count_file" \
          "$alerted_file"

        logger -t tranga-queue-watch \
          "Queue healthy: no requested, undownloaded chapter-source links."

        exit 0
      fi

      signature="$(sha256sum "$pending_file" | awk '{ print $1 }')"
      previous_signature="$(cat "$signature_file" 2>/dev/null || true)"

      if [[ "$signature" == "$previous_signature" ]]; then
        count="$(cat "$count_file" 2>/dev/null || printf '0')"

        [[ "$count" =~ ^[0-9]+$ ]] || count=0

        count=$((count + 1))
      else
        count=1
        rm -f "$alerted_file"
      fi

      printf '%s\n' "$signature" > "$signature_file"
      printf '%s\n' "$count" > "$count_file"

      if (( count < ALERT_AFTER )); then
        logger -t tranga-queue-watch \
          "Pending queue observed: $pending_count links; unchanged check $count/$ALERT_AFTER."

        exit 0
      fi

      # Avoid repeatedly alerting for the same exact blocked queue.
      if [[ "$(cat "$alerted_file" 2>/dev/null || true)" == "$signature" ]]; then
        exit 0
      fi

      message="Tranga queue may be blocked: $pending_count requested chapter-source links remained unchanged for $count consecutive checks. Report: $report_file"

      echo "$message" >&2
      logger -p daemon.err -t tranga-queue-watch "$message"

      if [[ -n "$NTFY_URL" ]]; then
        curl -fsS \
          -H 'Title: Tranga queue may be blocked' \
          -H 'Priority: high' \
          -d "$message" \
          "$NTFY_URL" >/dev/null
      fi

      printf '%s\n' "$signature" > "$alerted_file"

      # Make the first alert visible through systemctl --failed.
      # Later checks for the same incident exit successfully to avoid spam.
      exit 1
    '';
  };

in
{
  # Pre-create directories with the container user's UID/GID.
  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/tranga 0755 1000 1000 -"
    "d ${myConstants.paths.servicesSSD}/tranga/postgres 0755 1000 1000 -"
    "d ${myConstants.paths.disk4TB}/media/manga/tranga 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers = {
    # 1. Tranga Database
    "${myConstants.services.tranga-db.containerName}" = {
      image = "postgres:${myConstants.services.tranga-db.version}";
      environment = {
        POSTGRES_DB = "postgres";
        POSTGRES_USER = "postgres";
        POSTGRES_PASSWORD = "postgres_secret_password";

        LOG_LEVEL = "INFO";
        Logging__LogLevel__Default = "Information";
        Logging__LogLevel__Microsoft = "Warning";
        Logging__LogLevel__API = "Information";
      };
      volumes = [
        "${myConstants.paths.servicesSSD}/tranga/postgres:/var/lib/postgresql/data"
      ];
    };

    # 2. Tranga API
    "${myConstants.services.tranga-api.containerName}" = {
      image = "glax/tranga-api:${myConstants.services.tranga-api.version}";
      dependsOn = [ myConstants.services.tranga-db.containerName ];

      # Internal port for Tranga API is 6531. We bind it to localhost for Caddy.
      ports = [ (myConstants.bind myConstants.services.tranga-api.port) ];      

      environment = {
        TZ = "Europe/Paris";
        POSTGRES_HOST = myConstants.services.tranga-db.containerName;
        POSTGRES_USER = "postgres";
        POSTGRES_PASSWORD = "postgres_secret_password"; # Must match DB above
      };

      volumes = [
        # Configurations and Logs
        "${myConstants.paths.servicesSSD}/tranga:/usr/share/tranga-api"
        # Download directory mapped to the 4TB disk
        "${myConstants.paths.disk4TB}/media/manga/tranga:/Manga"
      ];

      extraOptions = [
        # Link containers internally so the API can resolve the DB hostname
        "--link=${myConstants.services.tranga-db.containerName}:${myConstants.services.tranga-db.containerName}"
      ];
    };

    # 3. Tranga Website (The Nuxt Frontend)
    "${myConstants.services.tranga.containerName}" = {
      image = "glax/tranga-website:${myConstants.services.tranga.version}";
      dependsOn = [ myConstants.services.tranga-api.containerName ];

      # The frontend image listens on port 80 internally
      ports = [ "172.17.0.1:${toString myConstants.services.tranga.port}:80" ];

      extraOptions = [
        "--link=${myConstants.services.tranga-api.containerName}:tranga-api"
      ];
    };
  };

  # Alert-only queue watchdog.
  #
  # It never disables or deletes chapters. It reports a queue as potentially
  # blocked when the exact same requested chapter-source links remain unchanged
  # for three consecutive checks.
  systemd.services.tranga-queue-watch = {
    description =
      "Detect a persistently blocked Tranga chapter queue";

    after = [
      trangaApiUnit
    ];

    wants = [
      trangaApiUnit
    ];

    environment = {
      TRANGA_API =
        "http://127.0.0.1:${toString myConstants.services.tranga-api.port}";

      TRANGA_STATE_DIR =
        "/var/lib/tranga-queue-watch";

      TRANGA_PAGE_SIZE =
        "100000";

      # With a 30-minute timer, three identical checks means approximately
      # one hour without queue progress.
      TRANGA_ALERT_AFTER =
        "3";

      # Empty disables ntfy.
      #
      # Example:
      # TRANGA_NTFY_URL = "https://ntfy.example.net/tranga";
      TRANGA_NTFY_URL =
        "";
    };

    serviceConfig = {
      Type = "oneshot";

      StateDirectory =
        "tranga-queue-watch";

      ExecStart =
        "${trangaQueueWatch}/bin/tranga-queue-watch";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  systemd.timers.tranga-queue-watch = {
    description =
      "Check the Tranga chapter queue every 30 minutes";

    wantedBy = [
      "timers.target"
    ];

    timerConfig = {
      OnBootSec = "10m";
      OnUnitActiveSec = "30m";
      Persistent = true;
      RandomizedDelaySec = "2m";

      Unit =
        "tranga-queue-watch.service";
    };
  };
}