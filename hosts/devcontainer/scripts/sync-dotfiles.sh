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

    if git clone "$REPO" "$DIR"; then
        # setup.sh uses Bash features, so execute it explicitly with bash.
        bash "$DIR/setup.sh" || warn "setup.sh failed"
    else
        warn "clone failed; continuing without dotfiles"
    fi
else
    git -C "$DIR" pull --ff-only ||
        warn "update failed; continuing with existing dotfiles"
fi
