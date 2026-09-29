# Opt-in, process-scoped bridge for Nix Python applications using host GPU libs.
# Does NOT allocate a GPU or install a driver. Paths depend on cluster runtime.
set -Eeuo pipefail
[[ $# -gt 0 ]] || { printf 'Usage: devcontainer-with-gpu-libs COMMAND [ARG ...]\n' >&2; exit 2; }
paths=${DEVCONTAINER_GPU_LIBRARY_PATH:-/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/lib/x86_64-linux-gnu:/usr/lib64}
export LD_LIBRARY_PATH="$paths${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$@"
