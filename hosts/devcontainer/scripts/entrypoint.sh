# No downloads, git clones, extension installs, or arbitrary dotfile execution.
set -Eeuo pipefail
umask 022

fail() { printf 'Devcontainer startup: %s\n' "$*" >&2; exit 1; }

[[ $(id -u) == 999 ]] || fail 'expected UID 999'
: "${HOME:?}"

for directory in "$HOME" /tmp /nix/store /nix/var/nix; do
  [[ -d $directory && -w $directory ]] || fail "$directory is not writable. Check the persistent volumes and their ownership; do not add sudo."
done

rm -f /tmp/devcontainer-ready

mkdir -p \
  "$HOME/.local/bin" \
  "$HOME/.local/state" \
  "$HOME/.cache" \
  "$HOME/.config/atuin" \
  "$HOME/.config/direnv" \
  "$HOME/workspaces" \
  "$XDG_RUNTIME_DIR"

chmod 700 "$XDG_RUNTIME_DIR"

# Clone on first boot, git pull on subsequent boots.
# Failure is non-fatal: an internet outage must not prevent VS Code attaching.
devcontainer-sync-dotfiles || true

# Container-specific defaults that are not personal dotfiles.
if [[ ! -e "$HOME/.config/atuin/config.toml" ]]; then
  cp /etc/devcontainer/atuin.toml "$HOME/.config/atuin/config.toml"
fi

if [[ ! -e "$HOME/.config/direnv/direnvrc" ]]; then
  cp /etc/devcontainer/direnvrc "$HOME/.config/direnv/direnvrc"
fi

nix path-info "$DEVCONTAINER_ROOT" >/dev/null

touch /tmp/devcontainer-ready

if [[ $# == 0 ]]; then
  set -- /bin/sleep infinity
fi

exec "$@"
