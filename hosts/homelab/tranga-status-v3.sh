#!/usr/bin/env bash
set -Eeuo pipefail

API="${TRANGA_API:-http://127.0.0.1:6531}"
PAGE_SIZE="${TRANGA_PAGE_SIZE:-100000}"
MODE="${TRANGA_MODE:-issues}" # issues, all, caught-up, inactive
API="${API%/}"

case "$MODE" in
  issues|all|caught-up|inactive) ;;
  *)
    printf 'Invalid TRANGA_MODE: %s (expected issues, all, caught-up, or inactive)\n' "$MODE" >&2
    exit 2
    ;;
esac

for command_name in curl jq column awk; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$command_name" >&2
    exit 127
  fi
done

summary_file="$(mktemp)"
pending_file="$(mktemp)"
trap 'rm -f "$summary_file" "$pending_file"' EXIT

printf 'STATUS\tMANGA_ACTIVE\tDB_RECORDS\tREQUESTED\tDONE\tPENDING\tLATEST_DB\tLATEST_REQUESTED\tRELEASE\tACTIVE_SOURCES\tMANGA\tMANGA_ID\n' > "$summary_file"
printf 'STATUS\tMANGA_ACTIVE\tMANGA\tCHAPTER\tSOURCE\tCHAPTER_ID\n' > "$pending_file"

# Scan every cached manga. Using /Downloading here would miss chapter-level
# requests whose parent manga connector is no longer marked for download.
mangas="$(curl -fsS "$API/v2/Manga")"
if ! jq -e 'type == "array"' >/dev/null <<< "$mangas"; then
  printf 'Unexpected response from %s/v2/Manga\n' "$API" >&2
  exit 1
fi

while IFS=$'\t' read -r manga_id manga_name release_status manga_active active_sources; do
  [[ -n "$manga_id" ]] || continue

  chapters="$(
    curl -fsS -X POST \
      "$API/v2/Chapters/Manga/$manga_id?page=1&pageSize=$PAGE_SIZE" \
      -H 'Content-Type: application/json' \
      -d '{}'
  )"

  if ! jq -e '.data | type == "array"' >/dev/null <<< "$chapters"; then
    printf 'Unexpected chapter response for %s (%s)\n' "$manga_name" "$manga_id" >&2
    continue
  fi

  stats="$(
    jq -r '
      (.data // []) as $all
      | [
          $all[]
          | select(any(.mangaConnectorIds[]?; .useForDownload == true))
        ] as $requested
      | [
          ($all | length),
          ($requested | length),
          ($requested | map(select(.downloaded == true)) | length),
          ($requested | map(select(.downloaded != true)) | length),
          (($all | first | .chapterNumber) // "-"),
          (($requested | first | .chapterNumber) // "-")
        ]
      | @tsv
    ' <<< "$chapters"
  )"

  IFS=$'\t' read -r db_records requested done pending latest_db latest_requested <<< "$stats"

  if (( pending > 0 )) && [[ "$manga_active" == "no" ]]; then
    status="ORPHAN_PENDING"
  elif (( pending > 0 )); then
    status="PENDING"
  elif [[ "$manga_active" == "yes" ]] && (( db_records == 0 )); then
    status="NO_RECORDS"
  elif [[ "$manga_active" == "yes" ]] && (( requested == 0 )); then
    status="NO_REQUESTS"
  elif [[ "$manga_active" == "yes" ]]; then
    status="CAUGHT_UP"
  else
    status="INACTIVE"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$status" "$manga_active" "$db_records" "$requested" "$done" "$pending" \
    "$latest_db" "$latest_requested" "$release_status" "${active_sources:--}" \
    "$manga_name" "$manga_id" >> "$summary_file"

  jq -r \
    --arg status "$status" \
    --arg active "$manga_active" \
    --arg manga "$manga_name" '
      (.data // [])[]
      | select(
          (.downloaded != true)
          and any(.mangaConnectorIds[]?; .useForDownload == true)
        )
      | [
          $status,
          $active,
          $manga,
          (
            "Ch." + (.chapterNumber // "?")
            + if (.title // "") == "" then "" else " - " + .title end
          ),
          ([
            .mangaConnectorIds[]?
            | select(.useForDownload == true)
            | .mangaConnectorName
          ] | unique | join(",")),
          .key
        ]
      | @tsv
    ' <<< "$chapters" >> "$pending_file"
done < <(
  jq -r '
    .[]
    | (
        [.mangaConnectorIds[]? | select(.useForDownload == true)]
      ) as $active_ids
    | [
        .key,
        .name,
        (.releaseStatus | tostring),
        (if ($active_ids | length) > 0 then "yes" else "no" end),
        ([$active_ids[] | .mangaConnectorName] | unique | join(","))
      ]
    | @tsv
  ' <<< "$mangas"
)

count_status() {
  local wanted="$1"
  awk -F '\t' -v wanted="$wanted" \
    'NR > 1 && $1 == wanted { count++ } END { print count + 0 }' \
    "$summary_file"
}

printf 'Tranga full-state summary\n\n'
printf '  CAUGHT_UP:      %s  active manga; all requested chapter records downloaded\n' "$(count_status CAUGHT_UP)"
printf '  PENDING:        %s  active manga with requested chapters not downloaded\n' "$(count_status PENDING)"
printf '  ORPHAN_PENDING: %s  inactive parent manga but requested chapter rows remain\n' "$(count_status ORPHAN_PENDING)"
printf '  NO_REQUESTS:    %s  active manga with chapter rows but no chapter requests\n' "$(count_status NO_REQUESTS)"
printf '  NO_RECORDS:     %s  active manga with no chapter rows\n' "$(count_status NO_RECORDS)"
printf '  INACTIVE:       %s  cached/search-result manga not marked active\n' "$(count_status INACTIVE)"
printf '\n'

case "$MODE" in
  issues)
    awk -F '\t' 'NR == 1 || ($1 != "CAUGHT_UP" && $1 != "INACTIVE")' "$summary_file"
    ;;
  caught-up)
    awk -F '\t' 'NR == 1 || $1 == "CAUGHT_UP"' "$summary_file"
    ;;
  inactive)
    awk -F '\t' 'NR == 1 || $1 == "INACTIVE"' "$summary_file"
    ;;
  all)
    cat "$summary_file"
    ;;
esac | column -s $'\t' -t

if (( $(wc -l < "$pending_file") > 1 )); then
  printf '\nPending or blocked chapter records\n\n'
  column -s $'\t' -t "$pending_file"
fi

cat <<'TEXT'

Definitions:
  CAUGHT_UP is not proof that the complete published manga is present.
  PENDING belongs to a manga currently marked active.
  ORPHAN_PENDING is especially important: the chapter scheduler can still retry
  a requested chapter even when its parent manga is not returned by /Manga/Downloading.
  NO_RECORDS means the selected source has not produced any chapter rows in Tranga.
TEXT
