{ pkgs, nixpkgsInput, stream ? false, ... }:

let
  inherit (pkgs) lib;
  mkScript = name: source: pkgs.writeShellScriptBin name (builtins.readFile source);

  entrypoint = mkScript "devcontainer-entrypoint" ./scripts/entrypoint.sh;
  seedNix = mkScript "devcontainer-seed-nix" ./scripts/seed-nix.sh;
  syncDotfiles = mkScript "devcontainer-sync-dotfiles" ./scripts/sync-dotfiles.sh;
  installExtensions = mkScript "devcontainer-install-extensions" ./scripts/install-extensions.sh;
  doctor = mkScript "devcontainer-doctor" ./scripts/doctor.sh;
  withGpuLibs = mkScript "devcontainer-with-gpu-libs" ./scripts/with-gpu-libs.sh;

  # Daily-use tools. Larger toolchains can be installed into the persistent
  # Nix profile or supplied by individual project flakes.
  basePackages = with pkgs; [
    bashInteractive coreutils findutils gnugrep gnused gawk
    gnutar gzip bzip2 xz zip unzip which diffutils patch
    procps psmisc util-linux iproute2 file less vim ncurses
    gitMinimal git-lfs openssh curl cacert iana-etc rsync
    nix nil uv python3 nodejs jq ripgrep fd patchelf
    direnv nix-direnv bash-preexec
    starship atuin tmux btop bat eza fzf tini
    entrypoint seedNix syncDotfiles installExtensions doctor withGpuLibs
  ];

  profile = pkgs.buildEnv {
    name = "devcontainer-tools";
    paths = basePackages;
    pathsToLink = [ "/bin" "/share" ];
    # Do not hide real collisions with ignoreCollisions = true.
  };

  # Compatibility for foreign ELF binaries (VS Code Server, vendor CLIs).
  # Not a general-purpose replacement for declaring project dependencies.
  compatibilityLibraries = with pkgs; [
    glibc stdenv.cc.cc.lib zlib openssl
  ];
  compatibilityPath = lib.makeLibraryPath compatibilityLibraries;
  loader = pkgs.stdenv.cc.bintools.dynamicLinker;

  registry = pkgs.writeText "devcontainer-registry.json" (builtins.toJSON {
    version = 2;
    flakes = [{
      from = { type = "indirect"; id = "nixpkgs"; };
      # Pin by revision WITHOUT embedding the entire nixpkgs source in the image.
      to = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        rev = nixpkgsInput.rev;
      };
    }];
  });

  # Real directories at the root, with deliberately selected symlinks.
  # Everything referenced by the image environment must be in this closure:
  # the init container copies this one root and Nix discovers its dependencies.
  root = pkgs.runCommand "devcontainer-root" { } ''
    mkdir -p "$out"/{bin,etc/nix,etc/devcontainer,opt,lib,lib64,usr/bin,usr/lib,usr/lib64,usr/local/bin}
    ln -s ${profile}/bin/* "$out/bin/"
    if [ ! -e "$out/bin/sh" ]; then ln -s bash "$out/bin/sh"; fi
    ln -s ${profile}/share "$out/share"
    ln -s ${pkgs.coreutils}/bin/env "$out/usr/bin/env"
    ln -s ${pkgs.bashInteractive}/bin/bash "$out/usr/bin/bash"
    ln -s ${pkgs.bashInteractive}/bin/bash "$out/usr/bin/sh"
    ln -s ${pkgs.glibc.bin}/bin/ldd "$out/bin/ldd"
    # VS Code's prerequisite checker probes these exact paths when ldconfig
    # is absent. Expose the real libraries; do not fake a NixOS ID or skip checks.
    # Loading is still handled by nix-ld, not a broad global library symlink farm.
    ln -s ${pkgs.glibc}/lib/libc.so.6 "$out/usr/lib/libc.so.6"
    ln -s ${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6 "$out/usr/lib/libstdc++.so.6"
    ln -s ${pkgs.nix-ld}/libexec/nix-ld "$out/lib64/ld-linux-x86-64.so.2"
    ln -s ${pkgs.nix-ld}/libexec/nix-ld "$out/lib/ld-linux-x86-64.so.2"
    ln -s ${pkgs.cacert}/etc/ssl "$out/etc/ssl"
    ln -s ${pkgs.iana-etc}/etc/services "$out/etc/services"
    ln -s ${pkgs.iana-etc}/etc/protocols "$out/etc/protocols"
    ln -s ${registry} "$out/etc/nix/registry.json"

    cat > "$out/etc/passwd" <<'PASSWD'
root:x:0:0:root:/root:/bin/bash
arthur:x:999:999:Arthur:/home/arthur:/bin/bash
PASSWD
    cat > "$out/etc/group" <<'GROUP'
root:x:0:
arthur:x:999:
GROUP
    printf 'passwd: files\ngroup: files\nhosts: files dns\n' > "$out/etc/nsswitch.conf"
    printf '/bin/bash\n/bin/sh\n' > "$out/etc/shells"
    cat > "$out/etc/os-release" <<'OSRELEASE'
NAME="Nix development container"
ID=nix-devcontainer
ID_LIKE=nixos
OSRELEASE
    cat > "$out/etc/nix/nix.conf" <<'NIXCONF'
experimental-features = nix-command flakes read-only-local-store
sandbox = false
build-users-group =
max-jobs = 2
cores = 2
auto-optimise-store = false
# Disable the unpinned global registry; /etc/nix/registry.json remains active.
flake-registry =
NIXCONF
    cat > "$out/etc/devcontainer/atuin.toml" <<'ATUIN'
auto_sync = false
update_check = false
sync_address = ""
style = "auto"
inline_height = 16
show_preview = true
enter_accept = true
ATUIN
    printf 'source %s/share/nix-direnv/direnvrc\n' '${pkgs.nix-direnv}' > "$out/etc/devcontainer/direnvrc"
    # Retain all runtime-library references in the copied / GC-rooted closure.
    printf '%s\n' '${compatibilityPath}' '${loader}' > "$out/etc/devcontainer/compatibility-paths"
  '';

  imageArguments = {
    name = "nix-devcontainer";
    tag = "latest";
    contents = [ root ];
    includeNixDB = true;
    # Layer count is not a size guarantee; the default already handles sharing.
    maxLayers = 100;
    fakeRootCommands = ''
      mkdir -p ./home/arthur ./tmp ./run
      chown 999:999 ./home/arthur
      chmod 0750 ./home/arthur
      chmod 1777 ./tmp
    '';
    config = {
      User = "999:999";
      WorkingDir = "/home/arthur";
      Entrypoint = [ "/bin/tini" "-g" "--" "/bin/devcontainer-entrypoint" ];
      Cmd = [ "/bin/sleep" "infinity" ];
      Env = [
        "USER=arthur"
        "LOGNAME=arthur"
        "HOME=/home/arthur"
        "SHELL=/bin/bash"
        "PATH=/home/arthur/.local/bin:/home/arthur/.nix-profile/bin:/home/arthur/.local/state/nix/profile/bin:/home/arthur/.local/state/nix/profiles/profile/bin:/bin:/usr/bin:/usr/local/bin"
        "XDG_CONFIG_HOME=/home/arthur/.config"
        "XDG_CACHE_HOME=/home/arthur/.cache"
        "XDG_STATE_HOME=/home/arthur/.local/state"
        "XDG_DATA_HOME=/home/arthur/.local/share"
        "XDG_RUNTIME_DIR=/tmp/runtime-999"
        "HISTFILE=/home/arthur/.bash_history"
        "LANG=C.UTF-8"
        "LC_ALL=C.UTF-8"
        "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        "GIT_SSL_CAINFO=/etc/ssl/certs/ca-bundle.crt"
        "NIX_REMOTE=local"
        "NIX_PATH=nixpkgs=flake:nixpkgs"
        "NPM_CONFIG_PREFIX=/home/arthur/.local"
        "UV_LINK_MODE=copy"
        "TERMINFO_DIRS=${pkgs.ncurses}/share/terminfo"
        "NIX_LD=${loader}"
        "NIX_LD_LIBRARY_PATH=${compatibilityPath}:/usr/local/nvidia/lib:/usr/local/nvidia/lib64:/usr/lib/x86_64-linux-gnu:/usr/lib64"
        "DEVCONTAINER_ROOT=${root}"
      ];
    };
  };
in
assert pkgs.stdenv.hostPlatform.system == "x86_64-linux";
(if stream then pkgs.dockerTools.streamLayeredImage else pkgs.dockerTools.buildLayeredImage) imageArguments
