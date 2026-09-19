set -Eeuo pipefail
id
printf '\nWritable directories:\n'
for directory in "$HOME" /tmp /nix/store /nix/var/nix; do
  [[ -w $directory ]] || { printf 'NOT WRITABLE: %s\n' "$directory" >&2; exit 1; }
  stat -c '%U:%G %a %n' "$directory"
done
printf '\nNix and loader:\n'
nix --version
nix path-info "$DEVCONTAINER_ROOT"
readlink -f /lib64/ld-linux-x86-64.so.2
ldd --version | sed -n '1p'
printf 'NIX_LD=%s\n' "$NIX_LD"
printf 'LD_LIBRARY_PATH=%s\n' "${LD_LIBRARY_PATH-<unset>}"
printf '\nPersistent profile paths in PATH:\n%s\n' "$PATH"
printf '\nNext: nix shell nixpkgs#hello -c hello\n'
printf 'A missing cached package may require a download or an unsandboxed build as your user.\n'
