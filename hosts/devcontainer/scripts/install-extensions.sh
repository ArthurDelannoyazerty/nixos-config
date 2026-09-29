# Run from an attached VS Code terminal, not from the pod entrypoint.
set -Eeuo pipefail

if ! command -v code >/dev/null 2>&1; then
  printf 'Run this command in an attached VS Code terminal (code is not in PATH).\n' >&2
  exit 1
fi

list=${1:-"$HOME/dotfiles/code/extensions.txt"}

[[ -r $list ]] || { printf 'Cannot read %s\n' "$list" >&2; exit 1; }

installed=$(code --list-extensions) || exit 1

failed=0
while IFS= read -r extension || [[ -n $extension ]]; do
  extension=${extension//$'\r'/}
  extension=${extension%%#*}
  extension="${extension#"${extension%%[![:space:]]*}"}"
  extension="${extension%"${extension##*[![:space:]]}"}"
  [[ -n $extension ]] || continue
  if [[ ! $extension =~ ^[A-Za-z0-9][A-Za-z0-9_-]*\.[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
    printf 'Invalid extension ID: %s\n' "$extension" >&2
    failed=1
    continue
  fi
  if grep -Fxiq -- "$extension" <<<"$installed"; then
    printf 'Already installed: %s\n' "$extension"
    continue
  fi
  if code --install-extension "$extension"; then
    installed+=$'\n'"$extension"
  else
    printf 'Failed: %s\n' "$extension" >&2
    failed=1
  fi
done < "$list"
exit "$failed"
