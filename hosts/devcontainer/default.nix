{ pkgs, dotfilesInput, ... }:

let
  devContainerConf = pkgs.writeTextDir "home/arthur/.devcontainer/devcontainer.json" ''
    {
      "name": "Nix Rancher Dev",
      "remoteUser": "arthur",
      "postAttachCommand": "/bin/entrypoint.sh true",
      "customizations": {
        "vscode": {
          "settings": {
            "terminal.integrated.defaultProfile.linux": "bash",
            "nix.enableLanguageServer": true,
            "nix.serverPath": "nil",
            "python.defaultInterpreterPath": "/usr/bin/python3"
          },
          "extensions": [
            "alexcvzz.vscode-sqlite",
            "antfu.theme-vitesse",
            "charliermarsh.ruff",
            "christian-kohler.path-intellisense",
            "codediagram.codediagram",
            "continue.continue",
            "eamodio.gitlens",
            "emilast.logfilehighlighter",
            "esbenp.prettier-vscode",
            "github.copilot",
            "github.copilot-chat",
            "google.geminicodeassist",
            "hediet.vscode-drawio",
            "irongeek.vscode-env",
            "jnoortheen.nix-ide",
            "johnpapa.vscode-peacock",
            "mechatroner.rainbow-csv",
            "meezilla.json",
            "mermaidchart.vscode-mermaid-chart",
            "mhutchie.git-graph",
            "monokai.theme-monokai-pro-vscode",
            "ms-azuretools.vscode-containers",
            "ms-kubernetes-tools.vscode-kubernetes-tools",
            "ms-python.debugpy",
            "ms-python.python",
            "ms-python.vscode-pylance",
            "ms-python.vscode-python-envs",
            "ms-toolsai.jupyter",
            "ms-toolsai.jupyter-keymap",
            "ms-toolsai.jupyter-renderers",
            "ms-toolsai.tensorboard",
            "ms-toolsai.vscode-jupyter-cell-tags",
            "ms-vscode-remote.remote-containers",
            "ms-vscode-remote.remote-ssh",
            "ms-vscode-remote.remote-ssh-edit",
            "ms-vscode-remote.remote-wsl",
            "ms-vscode-remote.vscode-remote-extensionpack",
            "ms-vscode.azure-repos",
            "ms-vscode.remote-explorer",
            "ms-vscode.remote-repositories",
            "ms-vscode.remote-server",
            "njpwerner.autodocstring",
            "njqdev.vscode-python-typehint",
            "pkief.material-icon-theme",
            "qwtel.sqlite-viewer",
            "redhat.vscode-yaml",
            "rioj7.command-variable",
            "ritwickdey.liveserver",
            "stackbreak.comment-divider",
            "tomoki1207.pdf",
            "torreysmith.copyfilepathandcontent"
          ]
        }
      }
    }
  '';

  dotfilesLayer = pkgs.runCommand "dotfiles-layer" { } ''
    mkdir -p $out/opt
    cp -r ${dotfilesInput} $out/opt/dotfiles
  '';

  entrypointScript = pkgs.writeScriptBin "entrypoint.sh" ''
    #!${pkgs.bash}/bin/bash
    set -e
    DOTFILES_DIR="/home/arthur/.dotfiles"
    BACKUP_SOURCE="/opt/dotfiles"
    MARKER_FILE="/home/arthur/.dotfiles_setup_complete"

    # --- 1. Clone/Restore Dotfiles (Idempotent: Only if dir doesn't exist) ---
    if [ ! -d "$DOTFILES_DIR" ]; then
      echo "--- First run detected: Installing Dotfiles ---"
      if git clone https://github.com/ArthurDelannoyazerty/dotfiles.git "$DOTFILES_DIR"; then
        echo "Git clone successful."
      else
        echo "Git clone failed, using baked-in copy..."
        cp -rL "$BACKUP_SOURCE" "$DOTFILES_DIR"
        chmod -R +w "$DOTFILES_DIR"
      fi
    fi
    
    # --- 2. Run Setup Script (Idempotent: Only if marker file doesn't exist) ---
    if [ ! -f "$MARKER_FILE" ]; then
      if [ -f "$DOTFILES_DIR/setup.sh" ]; then
        echo "Running setup.sh..."
        # Run setup.sh. If it fails, script exits (set -e) and marker is NOT created.
        sh "$DOTFILES_DIR/setup.sh"
        echo "Setup complete."
      fi
      # Create marker so we don't run this next time
      touch "$MARKER_FILE"
    else
      echo "Dotfiles setup already performed. Skipping."
    fi

    # --- 3. Execute Command (if arguments provided) ---
    # This allows the script to still be used as a Docker Entrypoint
    if [ "$#" -gt 0 ]; then
      exec "$@"
    fi
  '';

  atuinConfig = pkgs.writeTextDir "etc/atuin/config.toml" ''
    ## Server config ##
    auto_sync = false
    update_check = false
    sync_address = ""

    ## UI Settings ##
    style = "auto"
    inline_height = 16
    show_preview = true
    
    ## Behavior ##
    enter_accept = true
  '';

  devSetup = pkgs.runCommand "dev-setup" { } ''
    mkdir -p $out/etc
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "arthur:x:1000:1000:Arthur:/home/arthur:/bin/bash" >> $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
    echo "arthur:x:1000:" >> $out/etc/group
    echo "hosts: files dns" > $out/etc/nsswitch.conf
  '';

in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-devcontainer";
  tag = "latest";

  contents = with pkgs; [
    devSetup
    dotfilesLayer
    entrypointScript
    atuinConfig
    devContainerConf 
    
    # --- Base Utils ---
    bashInteractive
    coreutils
    git
    cacert
    curl
    wget
    iana-etc
    zip
    unzip
    openssh
    jq
    pkg-config
    nix-tree
    nil
    gnutar
    gzip
    procps 
    gnugrep
    gnused
    findutils
    gawk
    which
    util-linux
    glibc
    findutils 
    binutils
    # glibc.bin
    stdenv.cc.cc.lib
    
    # --- Terminal Tools ---
    atuin
    btop
    tree
    nvitop
    starship
    htop
    killall
    duf
    bat
    eza
    fzf
    tldr
    
    # --- Dev Tools ---
    vim
    python3
    nodejs
    gnumake
    gcc
    ripgrep
    fd
    nix
    uv
  ];

  # You can keep your fakeRootCommands for /usr/bin/env compatibility,
  # but we rely less on the library symlinks now.
  fakeRootCommands = ''
    mkdir -p ./home/arthur
    mkdir -p ./tmp
    mkdir -p ./usr/bin

    # --- 1. CLEANUP ---
    # Remove existing library dirs and any ldconfig that might have snuck in
    rm -rf ./lib ./lib64 ./usr/lib64
    rm -f ./bin/ldconfig ./sbin/ldconfig ./usr/sbin/ldconfig

    # --- 2. FHS DIRECTORY STRUCTURE ---
    mkdir -p ./usr/lib ./usr/bin ./sbin ./usr/sbin ./bin ./etc
    
    ln -sf usr/lib lib
    ln -sf usr/lib lib64
    ln -sf lib usr/lib64

    # --- 3. CONFIGURE LDCONFIG (THE FIX) ---
    
    # A. Create the config file telling ldconfig to look in /usr/lib
    echo "/usr/lib" > ./etc/ld.so.conf
    
    # B. Generate the cache NOW (during build)
    # This creates a valid ./etc/ld.so.cache that VS Code can read later
    ${pkgs.glibc.bin}/bin/ldconfig -r . -f /etc/ld.so.conf -C /etc/ld.so.cache || echo "Cache gen warning"

    # C. Create the Wrapper Script
    # VS Code calls 'ldconfig'. We intercept it and force it to use our 
    # valid cache file instead of the read-only Nix store path.
    cat <<EOF > ./bin/ldconfig
#!/bin/sh
exec ${pkgs.glibc.bin}/bin/ldconfig -C /etc/ld.so.cache "\$@"
EOF
    chmod +x ./bin/ldconfig
    
    # D. Symlink the wrapper to sbin (where VS Code looks)
    ln -sf ../bin/ldconfig ./sbin/ldconfig
    ln -sf ../bin/ldconfig ./usr/sbin/ldconfig

    # --- 4. POPULATE LIBRARIES ---
    
    # VS Code Scripts compatibility
    ln -sf ${pkgs.coreutils}/bin/env ./usr/bin/env

    # Dynamic Loader
    ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ./usr/lib/ld-linux-x86-64.so.2

    # Standard Libraries (Libstdc++, Glibc, GCC)
    find ${pkgs.stdenv.cc.cc.lib} -name "libstdc++.so.6*" -exec ln -sf {} ./usr/lib/ \;
    find ${pkgs.glibc}/lib -name "*.so*" -exec ln -sf {} ./usr/lib/ \;
    find ${pkgs.stdenv.cc.cc.lib} -name "libgcc_s.so.1" -exec ln -sf {} ./usr/lib/ \;

    # ----------------------------------------------

    # Permission setup
    chown -R 1000:1000 ./home/arthur
    chown -R 1000:1000 ./tmp
    chmod 755 ./home/arthur
    chmod 1777 ./tmp
  '';

  config = {
    User = "arthur";
    WorkingDir = "/home/arthur";
    Entrypoint = [ "/bin/entrypoint.sh" ];
    Cmd = [ "/bin/bash" ];
    
    Env = [
      "USER=arthur"
      "HOME=/home/arthur"
      "PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin" # Added sbin for ldconfig
      "HISTFILE=/home/arthur/.bash_history"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "GIT_SSL_CAINFO=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "PATH=/bin:/usr/bin:/usr/local/bin"
      "LANG=C.UTF-8"
      "LC_ALL=C.UTF-8"
      "ATUIN_CONFIG_DIR=/etc/atuin" 
      "LD_LIBRARY_PATH=/usr/lib"
    ];
  };
}