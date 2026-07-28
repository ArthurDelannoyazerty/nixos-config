{ config, pkgs, myConstants, ... }:

let
  serviceRoot = "${myConstants.paths.services4TB}/marimo";
  repoRoot = "${serviceRoot}/repo";
  notebooksRoot = "${repoRoot}/notebooks";
  stateRoot = "${serviceRoot}/state";

  # Keep credentials/configuration on the SSD, while notebook data stays on the 4 TB disk.
  sshRoot = "${myConstants.paths.servicesSSD}/marimo/ssh";

  containerPort = 8080;
  gitBranch = "main";
in
{
  systemd.tmpfiles.rules = [
    "d ${serviceRoot} 0750 1000 1000 -"
    "d ${repoRoot} 0750 1000 1000 -"
    "d ${notebooksRoot} 0750 1000 1000 -"
    "d ${stateRoot} 0750 1000 1000 -"
    "d ${stateRoot}/edit 0750 1000 1000 -"
    "d ${stateRoot}/apps 0750 1000 1000 -"
    "d ${sshRoot} 0700 1000 1000 -"
  ];

  # Browser editor. Protect this hostname with an Authentik policy limited to your account.
  virtualisation.oci-containers.containers.${myConstants.services.marimo.containerName} = {
    image = "ghcr.io/marimo-team/marimo:${myConstants.services.marimo.version}";
    user = "1000:1000";
    workdir = "/app/notebooks";

    cmd = [
      "marimo"
      "edit"
      "."
      "--sandbox"
      "--headless"
      "--host"
      "0.0.0.0"
      "--port"
      (toString containerPort)
      "--no-token"
    ];

    environment = {
      HOME = "/app/state/home";
      XDG_CACHE_HOME = "/app/state/cache";
      UV_CACHE_DIR = "/app/state/cache/uv";
      PYTHONPYCACHEPREFIX = "/app/state/pycache";
      MARIMO_IN_SECURE_ENVIRONMENT = "true";
      MARIMO_MANAGE_SCRIPT_METADATA = "true";
    };

    volumes = [
      "${notebooksRoot}:/app/notebooks"
      "${stateRoot}/edit:/app/state"
    ];

    # Caddy runs on the host, so no LAN-facing container port is required.
    ports = [
      "127.0.0.1:${toString myConstants.services.marimo.port}:${toString containerPort}"
    ];
  };

  # Read-only gallery used by Obsidian/Quartz links.
  virtualisation.oci-containers.containers.${myConstants.services.marimo-apps.containerName} = {
    image = "ghcr.io/marimo-team/marimo:${myConstants.services.marimo.version}";
    user = "1000:1000";
    workdir = "/app/notebooks";

    cmd = [
      "marimo"
      "run"
      "."
      "--watch"
      "--sandbox"
      "--headless"
      "--host"
      "0.0.0.0"
      "--port"
      (toString containerPort)
      "--no-token"
    ];

    environment = {
      HOME = "/app/state/home";
      XDG_CACHE_HOME = "/app/state/cache";
      UV_CACHE_DIR = "/app/state/cache/uv";
      PYTHONPYCACHEPREFIX = "/app/state/pycache";
      MARIMO_IN_SECURE_ENVIRONMENT = "true";
    };

    volumes = [
      "${notebooksRoot}:/app/notebooks:ro"
      "${stateRoot}/apps:/app/state"
    ];

    ports = [
      "127.0.0.1:${toString myConstants.services.marimo-apps.port}:${toString containerPort}"
    ];
  };

  # marimo saves files; it deliberately does not own your Git workflow.
  # This timer batches saves into commits and pushes them to the canonical remote.
  systemd.services.marimo-git-sync = {
    description = "Commit and push marimo notebooks";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    environment = {
      HOME = serviceRoot;
      GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh -i ${sshRoot}/id_ed25519 -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${sshRoot}/known_hosts";
    };

    serviceConfig = {
      Type = "oneshot";
      User = "1000";
      Group = "1000";
      UMask = "0077";
    };

    script = ''
      set -euo pipefail

      repo=${repoRoot}
      lock=${serviceRoot}/git-sync.lock

      exec 9>"$lock"
      ${pkgs.util-linux}/bin/flock -n 9 || exit 0

      if [ ! -d "$repo/.git" ]; then
        echo "marimo Git repository is not initialized at $repo; skipping"
        exit 0
      fi

      cd "$repo"

      ${pkgs.git}/bin/git config user.name "marimo-bot"
      ${pkgs.git}/bin/git config user.email "marimo@homelab"

      ${pkgs.git}/bin/git add --all
      if ! ${pkgs.git}/bin/git diff --cached --quiet; then
        ${pkgs.git}/bin/git commit -m "marimo autosave $(${pkgs.coreutils}/bin/date -u +%FT%TZ)"
      fi

      # The homelab is the only notebook writer. Rebase first if the remote changed.
      ${pkgs.git}/bin/git pull --rebase origin ${gitBranch}
      ${pkgs.git}/bin/git push origin HEAD:${gitBranch}
    '';
  };

  systemd.timers.marimo-git-sync = {
    description = "Regularly push marimo notebook changes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10m";
      OnUnitInactiveSec = "5m";
      Persistent = true;
      Unit = "marimo-git-sync.service";
    };
  };

  systemd.services."docker-${myConstants.services.marimo.containerName}".serviceConfig.RestartSec = "10s";
  systemd.services."docker-${myConstants.services.marimo-apps.containerName}".serviceConfig.RestartSec = "10s";
}
