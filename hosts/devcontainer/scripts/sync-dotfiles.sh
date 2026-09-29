#!/usr/bin/env bash
set -Eeuo pipefail

REPO="${DOTFILES_REPO:-https://github.com/ArthurDelannoyazerty/dotfiles.git}"
DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

warn() {
    printf 'dotfiles: %s\n' "$*" >&2
}

if [[ ! -d "$DIR/.git" ]]; then
    if [[ -e "$DIR" ]]; then
        warn "$DIR exists but is not a git repository; leaving it untouched"
        exit 0
    fi

    git clone "$REPO" "$DIR" ||
        {
            warn "clone failed; continuing without dotfiles"
            exit 0
        }
else
    git -C "$DIR" pull --ff-only ||
        warn "update failed; continuing with existing dotfiles"
fi

# setup.sh is idempotent, so run it after both clone and update.
if [[ -f "$DIR/setup.sh" ]]; then
    bash "$DIR/setup.sh" ||
        warn "setup.sh failed"
fi
