{ config, pkgs, myConstants, ... }:

{
  environment.systemPackages = with pkgs; [
    nodejs_22
    git
    git-lfs
    bash
    coreutils
    gnused
    gnugrep
    webhook
  ];

  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/quartz 0755 root root -"
  ];

  # ---------------------------------------------------------------------------
  # Webhook listener
  # ---------------------------------------------------------------------------

  systemd.services.webhook-quartz = {
    description = "Webhook receiver for Quartz";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      ExecStart =
        "${pkgs.webhook}/bin/webhook -hooks /etc/webhook/hooks.json -ip 127.0.0.1 -port 9001";

      User = "root";
    };
  };

  environment.etc."webhook/hooks.json".text = builtins.toJSON [
    {
      id = "rebuild-quartz";

      execute-command = "/run/current-system/sw/bin/systemctl";

      pass-arguments-to-command = [
        {
          source = "string";
          name = "start";
        }
        {
          source = "string";
          name = "build-quartz.service";
        }
      ];
    }
  ];

  # ---------------------------------------------------------------------------
  # Quartz build service
  # ---------------------------------------------------------------------------

  systemd.services.build-quartz = {
    description = "Build Quartz Static Site from local Forgejo";

    path = [
      pkgs.git
      pkgs.git-lfs
      pkgs.nodejs_22
      pkgs.bash
      pkgs.coreutils
      pkgs.gnused
      pkgs.gnugrep
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";

      EnvironmentFile =
        "-${myConstants.paths.servicesSSD}/quartz/secrets.env";
    };

    script = ''
      set -euo pipefail

      QUARTZ_DIR="${myConstants.paths.servicesSSD}/quartz"
      VAULT_DIR="$QUARTZ_DIR/vault"

      OUTPUT_DIR="$QUARTZ_DIR/public"
      NEXT_OUTPUT_DIR="$QUARTZ_DIR/public.next"
      OLD_OUTPUT_DIR="$QUARTZ_DIR/public.old"

      BUILD_LOG="$QUARTZ_DIR/.quartz-build.log"

      LOCAL_URL="http://127.0.0.1:${toString myConstants.services.forgejo.port}"
      PUBLIC_DOMAIN="${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}"

      export HOME="$QUARTZ_DIR"
      export NO_COLOR=1

      # Prevent Git LFS from downloading every LFS object automatically
      # during clone/reset. We explicitly pull the image types we need.
      export GIT_LFS_SKIP_SMUDGE=1

      cleanup() {
        rm -f "$HOME/.netrc"
        rm -f "$HOME/.gitconfig"
        rm -f "$BUILD_LOG"

        # Remove incomplete temporary output if the build failed.
        rm -rf "$NEXT_OUTPUT_DIR"
      }

      trap cleanup EXIT

      echo "Starting Quartz Build..."

      mkdir -p "$QUARTZ_DIR"

      # -----------------------------------------------------------------------
      # Forgejo credentials
      # -----------------------------------------------------------------------

      echo "machine 127.0.0.1 login quartz-builder password $FORGEJO_TOKEN" \
        > "$HOME/.netrc"

      chmod 600 "$HOME/.netrc"

      # Rewrite public Forgejo URLs to the local Forgejo server.
      #
      # This is useful in particular for Git LFS URLs returned by Forgejo.
      git config --global \
        url."$LOCAL_URL/".insteadOf \
        "https://$PUBLIC_DOMAIN/"

      git config --global \
        lfs.transfer.enableHrefRewrite \
        true

      # -----------------------------------------------------------------------
      # Step 1: Initialize Quartz engine if necessary
      # -----------------------------------------------------------------------

      if [ ! -f "$QUARTZ_DIR/package.json" ]; then
        echo "Initializing Quartz Engine (v5)..."

        rm -rf /tmp/quartz-init

        git clone \
          --branch v5 \
          https://github.com/jackyzha0/quartz.git \
          /tmp/quartz-init

        cp -a /tmp/quartz-init/. "$QUARTZ_DIR/"

        rm -rf /tmp/quartz-init
      fi

      # Install Quartz dependencies only when node_modules does not exist.
      if [ ! -d "$QUARTZ_DIR/node_modules" ]; then
        echo "Installing Quartz dependencies..."

        cd "$QUARTZ_DIR"

        npm ci
      fi

      # -----------------------------------------------------------------------
      # Step 2: Persistent Obsidian repository
      #
      # IMPORTANT:
      #
      # Do not clone the vault into /tmp and do not rsync into content/.
      #
      # We keep the actual Forgejo Git repository here. Quartz will build
      # directly from this directory, which means created-modified-date can
      # query the real Git history.
      #
      # It also means Git LFS keeps its local object cache between builds.
      # -----------------------------------------------------------------------

      if [ ! -d "$VAULT_DIR/.git" ]; then
        echo "Cloning Obsidian vault..."

        rm -rf "$VAULT_DIR"

        git clone \
          "$LOCAL_URL/arthur-delannoy/obsidian.git" \
          "$VAULT_DIR"
      else
        echo "Updating Obsidian vault..."

        cd "$VAULT_DIR"

        # Undo sanitizer changes left in the working tree from a previous
        # build.
        git reset --hard HEAD

        # Remove generated/untracked files from previous builds.
        git clean -fd

        git fetch origin --prune

        DEFAULT_BRANCH="$(
          git symbolic-ref \
            --quiet \
            --short \
            refs/remotes/origin/HEAD \
            2>/dev/null |
          sed 's#^origin/##' ||
          true
        )"

        # Fallback when origin/HEAD is not configured.
        if [ -z "$DEFAULT_BRANCH" ]; then
          DEFAULT_BRANCH="$(git branch --show-current || true)"
        fi

        if [ -z "$DEFAULT_BRANCH" ]; then
          DEFAULT_BRANCH="main"
        fi

        echo "Using vault branch: $DEFAULT_BRANCH"

        git checkout \
          -B "$DEFAULT_BRANCH" \
          "origin/$DEFAULT_BRANCH"

        git reset \
          --hard \
          "origin/$DEFAULT_BRANCH"
      fi

      # -----------------------------------------------------------------------
      # Step 3: Git LFS
      #
      # Because VAULT_DIR persists, downloaded LFS objects remain cached
      # inside VAULT_DIR/.git/lfs and do not need to be fetched from Forgejo
      # again on every build.
      # -----------------------------------------------------------------------

      cd "$VAULT_DIR"

      git lfs install --local

      echo "Updating LFS image assets..."

      git lfs pull \
        --include="*.png,*.jpg,*.jpeg,*.gif,*.webp,*.svg"

      # -----------------------------------------------------------------------
      # Step 4: Ensure an index exists
      #
      # This modifies only the build checkout, never Forgejo.
      # -----------------------------------------------------------------------

      if [ ! -f "$VAULT_DIR/index.md" ]; then
        for candidate in Home.md home.md README.md readme.md; do
          if [ -f "$VAULT_DIR/$candidate" ]; then
            echo "Using $candidate as generated index.md..."

            cp \
              "$VAULT_DIR/$candidate" \
              "$VAULT_DIR/index.md"

            break
          fi
        done
      fi

      # -----------------------------------------------------------------------
      # Step 5: Install configured Quartz plugins
      #
      # Quartz v5 uses quartz.config.yaml when present and falls back to
      # quartz.config.default.yaml otherwise.
      # -----------------------------------------------------------------------

      cd "$QUARTZ_DIR"

      if [ -f "$QUARTZ_DIR/quartz.config.yaml" ]; then
        echo "Using Quartz configuration: quartz.config.yaml"
      else
        echo "Using Quartz configuration: quartz.config.default.yaml"
      fi

      npx quartz plugin install --from-config

      # -----------------------------------------------------------------------
      # Step 6: Conservative Markdown/frontmatter preprocessor
      #
      # This runs ONLY against the persistent build checkout.
      # Forgejo is never modified.
      #
      # Behaviour:
      #
      #   valid frontmatter:
      #       untouched
      #
      #   UTF-8 BOM:
      #       removed
      #
      #   tabs in frontmatter:
      #       retry after converting tabs to two spaces
      #
      #   unclosed / obviously invalid frontmatter:
      #       prepend an HTML comment, preventing Quartz/gray-matter from
      #       seeing a frontmatter delimiter at the beginning of the note
      #
      # Example fallback:
      #
      #   ---
      #   broken yaml
      #   ---
      #
      # becomes:
      #
      #   <!-- quartz: frontmatter disabled for this build -->
      #   ---
      #   broken yaml
      #   ---
      #
      # Nothing from the note is deleted.
      # -----------------------------------------------------------------------

      echo "Checking Markdown frontmatter..."

      node - "$VAULT_DIR" <<'EOF'
      import fs from "node:fs";
      import path from "node:path";
      import { parseDocument } from "yaml";

      const root = process.argv[2];

      const disabledMarker =
        "<!-- quartz: frontmatter disabled for this build -->";

      function getMarkdownFiles(dir) {
        const files = [];

        for (
          const entry of fs.readdirSync(
            dir,
            { withFileTypes: true },
          )
        ) {
          // Never walk Git internals or Obsidian's application directory.
          if (
            entry.isDirectory() &&
            (
              entry.name === ".git" ||
              entry.name === ".obsidian"
            )
          ) {
            continue;
          }

          const fullPath = path.join(dir, entry.name);

          if (entry.isDirectory()) {
            files.push(...getMarkdownFiles(fullPath));
          } else if (
            entry.isFile() &&
            entry.name.toLowerCase().endsWith(".md")
          ) {
            files.push(fullPath);
          }
        }

        return files;
      }

      function parseYaml(value) {
        try {
          const document = parseDocument(
            value,
            {
              strict: true,
              uniqueKeys: true,
            },
          );

          if (document.errors.length > 0) {
            return {
              valid: false,
              error: document.errors[0].message,
            };
          }

          const parsed = document.toJS();

          // Obsidian/Quartz frontmatter should be a mapping/object.
          if (
            parsed !== null &&
            (
              typeof parsed !== "object" ||
              Array.isArray(parsed)
            )
          ) {
            return {
              valid: false,
              error: "frontmatter is not a YAML mapping",
            };
          }

          return {
            valid: true,
            error: null,
          };
        } catch (error) {
          return {
            valid: false,
            error:
              error instanceof Error
                ? error.message.split("\n")[0]
                : String(error),
          };
        }
      }

      function disableFrontmatter(file, text, reason) {
        if (text.startsWith(disabledMarker)) {
          return false;
        }

        fs.writeFileSync(
          file,
          disabledMarker + "\n" + text,
          "utf8",
        );

        console.log(
          "[frontmatter -> markdown] " +
            path.relative(root, file) +
            ": " +
            reason,
        );

        return true;
      }

      const files = getMarkdownFiles(root);

      let validCount = 0;
      let bomCount = 0;
      let tabsCount = 0;
      let disabledCount = 0;

      for (const file of files) {
        let text = fs.readFileSync(file, "utf8");

        if (text.startsWith(disabledMarker)) {
          continue;
        }

        // Strip UTF-8 BOM.
        if (text.charCodeAt(0) === 0xfeff) {
          text = text.slice(1);

          fs.writeFileSync(
            file,
            text,
            "utf8",
          );

          bomCount++;

          console.log(
            "[frontmatter] removed BOM: " +
              path.relative(root, file),
          );
        }

        /*
         * Quartz trims the file before running transformers, so inspect the
         * trimmed representation here too. This catches:
         *
         *     <blank line>
         *     ---
         *     foo: bar
         *     ---
         */
        const effective = text.trim();

        if (
          !effective.startsWith("---\n") &&
          !effective.startsWith("---\r\n")
        ) {
          continue;
        }

        const eol =
          effective.includes("\r\n")
            ? "\r\n"
            : "\n";

        const lines = effective.split(/\r?\n/);

        if (lines[0] !== "---") {
          continue;
        }

        let closingIndex = -1;

        for (let i = 1; i < lines.length; i++) {
          if (lines[i] === "---") {
            closingIndex = i;
            break;
          }
        }

        // Frontmatter opener with no closer.
        if (closingIndex === -1) {
          if (
            disableFrontmatter(
              file,
              text,
              "unclosed frontmatter",
            )
          ) {
            disabledCount++;
          }

          continue;
        }

        const rawYaml = lines
          .slice(1, closingIndex)
          .join("\n");

        let result = parseYaml(rawYaml);

        if (result.valid) {
          validCount++;
          continue;
        }

        // Try the only automatic YAML mutation we consider safe:
        // replace tabs inside the YAML block with two spaces.
        if (rawYaml.includes("\t")) {
          const repairedYaml =
            rawYaml.replace(/\t/g, "  ");

          const repaired =
            parseYaml(repairedYaml);

          if (repaired.valid) {
            const originalLines =
              text.split(/\r?\n/);

            /*
             * Locate the frontmatter in the actual source. Normally this is
             * line zero. If leading blank lines exist, locate the first ---
             * after them.
             */
            let opening = -1;

            for (
              let i = 0;
              i < originalLines.length;
              i++
            ) {
              if (
                originalLines[i].trim() === ""
              ) {
                continue;
              }

              if (originalLines[i] === "---") {
                opening = i;
              }

              break;
            }

            if (opening >= 0) {
              let close = -1;

              for (
                let i = opening + 1;
                i < originalLines.length;
                i++
              ) {
                if (originalLines[i] === "---") {
                  close = i;
                  break;
                }
              }

              if (close >= 0) {
                const repairedLines =
                  repairedYaml.split("\n");

                originalLines.splice(
                  opening + 1,
                  close - opening - 1,
                  ...repairedLines,
                );

                fs.writeFileSync(
                  file,
                  originalLines.join(
                    text.includes("\r\n")
                      ? "\r\n"
                      : "\n",
                  ),
                  "utf8",
                );

                tabsCount++;

                console.log(
                  "[frontmatter] repaired tabs: " +
                    path.relative(root, file),
                );

                continue;
              }
            }
          }
        }

        if (
          disableFrontmatter(
            file,
            text,
            result.error ?? "invalid YAML",
          )
        ) {
          disabledCount++;
        }
      }

      console.log("");
      console.log("Frontmatter check complete:");
      console.log(
        "  valid frontmatter:   " + validCount,
      );
      console.log(
        "  BOM removed:         " + bomCount,
      );
      console.log(
        "  tab blocks repaired: " + tabsCount,
      );
      console.log(
        "  YAML disabled:       " + disabledCount,
      );
      EOF

      # -----------------------------------------------------------------------
      # Helper: disable frontmatter for one file after Quartz itself rejects
      # it.
      #
      # This is the second safety layer. It handles cases where the "yaml"
      # parser above accepts something but Quartz's note-properties/js-yaml
      # implementation does not.
      # -----------------------------------------------------------------------

      disable_frontmatter_for_quartz() {
        local file="$1"

        node - "$file" <<'EOF'
      import fs from "node:fs";

      const file = process.argv[2];

      const marker =
        "<!-- quartz: frontmatter disabled for this build -->";

      let text =
        fs.readFileSync(file, "utf8");

      if (text.charCodeAt(0) === 0xfeff) {
        text = text.slice(1);
      }

      if (text.startsWith(marker)) {
        console.error(
          "Frontmatter is already disabled for: " +
            file,
        );

        process.exit(42);
      }

      fs.writeFileSync(
        file,
        marker + "\n" + text,
        "utf8",
      );
      EOF
      }

      # -----------------------------------------------------------------------
      # Step 7: Build Quartz directly from the Git-tracked vault
      #
      # This is the important fix for:
      #
      #   "isn't yet tracked by git, dates will be inaccurate"
      #
      # created-modified-date now discovers VAULT_DIR/.git rather than the
      # Quartz engine repository.
      # -----------------------------------------------------------------------

      echo ""
      echo "Building Quartz directly from:"
      echo "  $VAULT_DIR"

      rm -rf "$NEXT_OUTPUT_DIR"

      MAX_YAML_FALLBACKS=50
      YAML_FALLBACKS=0

      while true; do
        : > "$BUILD_LOG"

        if npx quartz build \
          --directory "$VAULT_DIR" \
          --output "$NEXT_OUTPUT_DIR" \
          2>&1 |
          tee "$BUILD_LOG"
        then
          break
        fi

        echo ""
        echo "Quartz build failed."

        # Only automatically recover when note-properties is involved.
        # Other Quartz errors remain fatal.
        if ! grep -q "note-properties" "$BUILD_LOG"; then
          echo "Failure is not a note-properties/frontmatter error."
          echo "No automatic Markdown modification will be attempted."

          exit 1
        fi

        FAILED_REPORTED="$(
          sed -n \
            's/.*Failed to process markdown `\([^`]*\)`.*/\1/p' \
            "$BUILD_LOG" |
          tail -n 1
        )"

        if [ -z "$FAILED_REPORTED" ]; then
          echo "Could not determine which Markdown file Quartz rejected."
          exit 1
        fi

        FAILED_FILE=""

        # Quartz can report either an absolute or relative path depending on
        # the input path it received.
        if [ -f "$FAILED_REPORTED" ]; then
          FAILED_FILE="$FAILED_REPORTED"
        elif [ -f "$QUARTZ_DIR/$FAILED_REPORTED" ]; then
          FAILED_FILE="$QUARTZ_DIR/$FAILED_REPORTED"
        elif [ -f "$VAULT_DIR/$FAILED_REPORTED" ]; then
          FAILED_FILE="$VAULT_DIR/$FAILED_REPORTED"
        fi

        if [ -z "$FAILED_FILE" ]; then
          echo "Quartz reported:"
          echo "  $FAILED_REPORTED"
          echo ""
          echo "But that file could not be resolved inside the build checkout."

          exit 1
        fi

        case "$FAILED_FILE" in
          "$VAULT_DIR"/*)
            ;;
          *)
            echo "Refusing to modify path outside vault:"
            echo "  $FAILED_FILE"

            exit 1
            ;;
        esac

        if [ "$YAML_FALLBACKS" -ge "$MAX_YAML_FALLBACKS" ]; then
          echo "Reached YAML fallback limit:"
          echo "  $MAX_YAML_FALLBACKS"

          exit 1
        fi

        YAML_FALLBACKS=$((YAML_FALLBACKS + 1))

        echo ""
        echo "Quartz rejected frontmatter in:"
        echo "  $FAILED_FILE"
        echo ""
        echo "Publishing that note as normal Markdown instead."
        echo "Fallback $YAML_FALLBACKS / $MAX_YAML_FALLBACKS"

        if ! disable_frontmatter_for_quartz "$FAILED_FILE"; then
          echo ""
          echo "Frontmatter was already disabled for this note."
          echo "The remaining error is therefore not recoverable by"
          echo "disabling YAML frontmatter."

          exit 1
        fi

        # Quartz cleans the output directory at the beginning of builds.
        rm -rf "$NEXT_OUTPUT_DIR"
      done

      # -----------------------------------------------------------------------
      # Step 8: Atomically-ish replace the served site
      #
      # A broken build never wipes the currently served public directory.
      # Quartz builds into public.next first.
      # -----------------------------------------------------------------------

      chmod -R o+rX "$NEXT_OUTPUT_DIR"

      rm -rf "$OLD_OUTPUT_DIR"

      if [ -d "$OUTPUT_DIR" ]; then
        mv \
          "$OUTPUT_DIR" \
          "$OLD_OUTPUT_DIR"
      fi

      mv \
        "$NEXT_OUTPUT_DIR" \
        "$OUTPUT_DIR"

      rm -rf "$OLD_OUTPUT_DIR"

      echo ""
      echo "Quartz build completed."
      echo "YAML fallbacks during Quartz build: $YAML_FALLBACKS"
      echo "Output: $OUTPUT_DIR"
    '';
  };
}