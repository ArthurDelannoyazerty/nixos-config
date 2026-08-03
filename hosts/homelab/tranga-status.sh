#!/usr/bin/env bash
set -Eeuo pipefail

API="${TRANGA_API:-http://127.0.0.1:6531}"
PAGE_SIZE="${TRANGA_PAGE_SIZE:-100000}"
MODE="${TRANGA_MODE:-issues}" # issues, all, caught-up
API="${API%/}"

case "$MODE" in
  issues|all|caught-up) ;;
  *)
    printf 'Invalid TRANGA_MODE: %s (expected issues, all, or caught-up)\n' "$MODE" >&2
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

printf 'STATUS\tDB_RECORDS\tREQUESTED\tDONE\tPENDING\tLATEST_DB\tLATEST_REQUESTED\tRELEASE\tSOURCES\tMANGA\tMANGA_ID\n' > "$summary_file"
printf 'MANGA\tCHAPTER\tSOURCE\tCHAPTER_ID\n' > "$pending_file"

mangas="$(curl -fsS "$API/v2/Manga/Downloading")"
if ! jq -e 'type == "array"' >/dev/null <<< "$mangas"; then
  printf 'Unexpected response from %s/v2/Manga/Downloading\n' "$API" >&2
  exit 1
fi

while IFS=$'\t' read -r manga_id manga_name release_status sources; do
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

  if (( db_records == 0 )); then
    status="NO_RECORDS"
  elif (( requested == 0 )); then
    status="NO_REQUESTS"
  elif (( pending == 0 )); then
    status="CAUGHT_UP"
  else
    status="PENDING"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$status" "$db_records" "$requested" "$done" "$pending" \
    "$latest_db" "$latest_requested" "$release_status" "$sources" \
    "$manga_name" "$manga_id" >> "$summary_file"

  jq -r --arg manga "$manga_name" '
    (.data // [])[]
    | select(
        (.downloaded != true)
        and any(.mangaConnectorIds[]?; .useForDownload == true)
      )
    | [
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
    | [
        .key,
        .name,
        (.releaseStatus | tostring),
        ([
          .mangaConnectorIds[]?
          | select(.useForDownload == true)
          | .mangaConnectorName
        ] | unique | join(","))
      ]
    | @tsv
  ' <<< "$mangas"
)

count_status() {
  local wanted="$1"
  awk -F '\t' -v wanted="$wanted" 'NR > 1 && $1 == wanted { count++ } END { print count + 0 }' "$summary_file"
}

printf 'Tranga download-state summary\n\n'
printf '  CAUGHT_UP:   %s  all requested chapter records downloaded\n' "$(count_status CAUGHT_UP)"
printf '  PENDING:     %s  at least one requested chapter not downloaded\n' "$(count_status PENDING)"
printf '  NO_REQUESTS: %s  chapter records exist, but none are requested\n' "$(count_status NO_REQUESTS)"
printf '  NO_RECORDS:  %s  no chapter records exist in Tranga\n' "$(count_status NO_RECORDS)"
printf '\n'

case "$MODE" in
  issues)
    awk -F '\t' 'NR == 1 || $1 != "CAUGHT_UP"' "$summary_file"
    ;;
  caught-up)
    awk -F '\t' 'NR == 1 || $1 == "CAUGHT_UP"' "$summary_file"
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
  It only means every chapter record currently requested in Tranga is downloaded.
  DB_RECORDS counts every chapter row Tranga currently knows for that manga.
  REQUESTED counts rows having at least one connector marked useForDownload=true.
TEXT
