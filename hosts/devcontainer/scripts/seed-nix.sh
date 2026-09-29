# Executed only by the non-root init container, using its ORIGINAL image store.
# The persistent volume is mounted at /persist, NOT at /nix, in this container.
set -Eeuo pipefail
umask 022
export PATH=/bin:/usr/bin

fail() { printf 'Nix initialization: %s\n' "$*" >&2; exit 1; }
[[ $(id -u) == 999 ]] || fail 'expected UID 999'
: "${DEVCONTAINER_ROOT:?image is missing DEVCONTAINER_ROOT}"
[[ $DEVCONTAINER_ROOT == /nix/store/* ]] || fail 'invalid image root'
destination=${1:-/persist}
[[ $destination =~ ^/[A-Za-z0-9/_-]+$ && $destination != / && $destination != /nix ]] || fail 'invalid destination'
[[ -d $destination && -w $destination ]] || fail "$destination must be a writable volume; ask the storage administrator to provision access for UID/GID 999"

# Do not try to write caches under the read-only image home directory.
export HOME=/tmp/nix-seed-home
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_STATE_HOME=$HOME/.local/state
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
exec 9>"$destination/.seed.lock"
flock 9

# read-only=true is ONLY for the immutable SOURCE database.
# 'root' keeps the logical store /nix/store, but physically writes
# /persist/nix/store and /persist/nix/var/nix. No build/chroot is done here.
# The main container mounts /persist/nix at /nix before starting.
# --no-check-sigs trusts this image's locally built closure only; it does not
# disable signature verification for subsequent internet package downloads.
nix copy \
  --from 'local?read-only=true' \
  --to "local?root=$destination" \
  --no-check-sigs \
  "$DEVCONTAINER_ROOT"

# Merge imports through Nix; NEVER overwrite an existing database with cp.
# Protect the CURRENT image closure from the user's garbage collection.
roots="$destination/nix/var/nix/gcroots"
mkdir -p "$roots"
ln -sfn "$DEVCONTAINER_ROOT" "$roots/.devcontainer-image.next"
mv -Tf "$roots/.devcontainer-image.next" "$roots/devcontainer-image"
printf 'Nix store initialized for %s\n' "$DEVCONTAINER_ROOT"
