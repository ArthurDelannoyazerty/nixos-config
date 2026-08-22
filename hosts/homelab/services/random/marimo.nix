{ config, pkgs, myConstants, ... }:

let
  serviceRoot = "${myConstants.paths.services4TB}/marimo";
  repoRoot = "${serviceRoot}/repo";
  notebooksRoot = "${repoRoot}/notebooks";
  stateRoot = "${serviceRoot}/state";
  publicRoot = "${myConstants.paths.servicesSSD}/marimo-public";

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
    "d ${stateRoot}/tmp 0750 1000 1000 -"
    "d ${publicRoot} 0755 1000 1000 -" 
    "d ${sshRoot} 0700 1000 1000 -"

    # Write the override rule to allow pyzmq versions to resolve cleanly
    "f+ ${stateRoot}/edit/overrides.txt 0644 1000 1000 - pyzmq>=27.0.0"
    "f+ ${stateRoot}/apps/overrides.txt 0644 1000 1000 - pyzmq>=27.0.0"
  ];

  # Browser editor (Full Sandboxing Enabled)
  virtualisation.oci-containers.containers.${myConstants.services.marimo.containerName} = {
    image = "ghcr.io/marimo-team/marimo:${myConstants.services.marimo.version}";
    user = "1000:1000";
    workdir = "/workspace";

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
      XDG_DATA_HOME = "/app/state/data";
      UV_CACHE_DIR = "/app/state/cache/uv";
      PYTHONPYCACHEPREFIX = "/app/state/pycache";
      TMPDIR = "/app/state/tmp";

      # Enable UV to download Python versions dynamically for each sandbox
      UV_PYTHON_DOWNLOADS = "auto";
      UV_PYTHON_PREFERENCE = "managed";
      UV_PYTHON = "3.12"; # Standard target for compatibility with all wheels
      UV_LINK_MODE = "copy";

      UV_OVERRIDE = "/app/state/overrides.txt";
      UV_NO_CONFIG = "true";

      MARIMO_IN_SECURE_ENVIRONMENT = "true";
      MARIMO_MANAGE_SCRIPT_METADATA = "true";
    };

    volumes = [
      "${notebooksRoot}:/workspace"
      "${stateRoot}/edit:/app/state"
      "${stateRoot}/tmp:/app/state/tmp"
    ];

    # Caddy runs on the host, so no LAN-facing container port is required.
    ports = [
      "127.0.0.1:${toString myConstants.services.marimo.port}:${toString containerPort}"
    ];
  };

  # Read-only gallery
  virtualisation.oci-containers.containers.${myConstants.services.marimo-apps.containerName} = {
    image = "ghcr.io/marimo-team/marimo:${myConstants.services.marimo.version}";
    user = "1000:1000";
    workdir = "/workspace";

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
      XDG_DATA_HOME = "/app/state/data";
      UV_CACHE_DIR = "/app/state/cache/uv";
      PYTHONPYCACHEPREFIX = "/app/state/pycache";
      TMPDIR = "/app/state/tmp";

      UV_PYTHON_DOWNLOADS = "auto";
      UV_PYTHON_PREFERENCE = "managed";
      UV_PYTHON = "3.12";
      UV_LINK_MODE = "copy";

      # Tell UV to use our override file and ignore parent configs
      UV_OVERRIDE = "/app/state/overrides.txt";
      UV_NO_CONFIG = "true";

      MARIMO_IN_SECURE_ENVIRONMENT = "true";
    };

    volumes = [
      "${notebooksRoot}:/workspace:ro"
      "${stateRoot}/apps:/app/state"
      "${stateRoot}/tmp:/app/state/tmp"
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


  systemd.services.marimo-public-export = {
    description = "Export Marimo notebooks to WASM";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "1000";
      Group = "1000";
    };
    script = ''
      ${pkgs.docker}/bin/docker run --rm \
        -v ${serviceRoot}:/workspace/service:ro \
        -v ${publicRoot}:/app/public \
        -u "1000:1000" \
        ghcr.io/marimo-team/marimo:${myConstants.services.marimo.version} \
        sh -c '
          shared_assets="/app/public/_shared_assets"
          mkdir -p "$shared_assets"
          tmp_index="/tmp/marimo_index.html"
          
          echo "<!DOCTYPE html><html><head><title>Public Notebooks</title><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><style>body{font-family: sans-serif; margin: 2rem; background: #0f172a; color: #f8fafc;} h1{color: #38bdf8;} a{color: #e2e8f0; text-decoration: none; font-size: 1.2rem; display: block; margin: 0.5rem 0; padding: 1rem; background: #1e293b; border-radius: 0.5rem; transition: background 0.2s;} a:hover{background: #334155;} .container{max-width: 800px; margin: 0 auto;}</style></head><body><div class=\"container\"><h1>Marimo Public Gallery</h1>" > "$tmp_index"

          # 1. Export changed notebooks
          find /workspace/service/repo/notebooks -name "*.py" | sort | while read -r file; do
            relpath="''${file#/workspace/service/repo/notebooks/}"
            name="''${relpath%.py}"
            
            outdir="/app/public/$name"
            mkdir -p "$outdir"
            
            # SMART BUILD: Only export if index.html is missing or source .py is newer
            if [ ! -f "$outdir/index.html" ] || [ "$file" -nt "$outdir/index.html" ]; then
              echo "Exporting $name..."
              marimo export html-wasm "$file" -o "$outdir" --mode run
              
              # DEDUPLICATION: Copy newly generated assets to shared dir and remove local copy
              if [ -d "$outdir/assets" ] && [ ! -L "$outdir/assets" ]; then
                cp -ru "$outdir/assets"/* "$shared_assets/" 2>/dev/null || true
                rm -rf "$outdir/assets"
              fi
            fi
            
            # Create a relative symlink pointing to the central shared assets folder
            if [ ! -L "$outdir/assets" ]; then
              rm -rf "$outdir/assets"
              ln -s -r "$shared_assets" "$outdir/assets"
            fi

            echo "<a href=\"/$name/\">$name</a>" >> "$tmp_index"
          done

          echo "</div></body></html>" >> "$tmp_index"
          mv "$tmp_index" /app/public/index.html

          # 2. CLEANUP: Remove exported directories for deleted notebooks
          find /app/public -name "index.html" | while read -r html_file; do
            if [ "$html_file" = "/app/public/index.html" ]; then continue; fi
            
            dir=$(dirname "$html_file")
            rel_dir="''${dir#/app/public/}"
            source_py="/workspace/service/repo/notebooks/$rel_dir.py"
            
            if [ ! -f "$source_py" ]; then
              echo "Removing deleted notebook export: $rel_dir"
              rm -rf "$dir"
            fi
          done

          # Clean empty parent directories
          find /app/public -type d -empty -delete 2>/dev/null || true

          chmod -R 755 /app/public
        '
    '';
  };


  # --- REAL-TIME WATCHER ---
  systemd.services.marimo-public-watcher = {
    description = "Watch Marimo notebooks and trigger WASM export";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    script = ''
      # Uses inotify to instantly trigger an export when a file is saved or modified
      ${pkgs.inotify-tools}/bin/inotifywait -m -r -e close_write,moved_to,create,delete ${notebooksRoot} | while read path action file; do
        if [[ "$file" == *.py ]]; then
          echo "Change detected in $file, triggering export..."
          # Systemd automatically handles queueing if an export is already actively running
          /run/current-system/sw/bin/systemctl start marimo-public-export.service
        fi
      done
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };


}
