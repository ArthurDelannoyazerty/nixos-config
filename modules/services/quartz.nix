{ config, pkgs, myConstants, ... }:

{
  # 1. Provide dependencies
  environment.systemPackages = with pkgs;[
    nodejs
    git
    git-lfs
    rsync
    bash
    coreutils
    webhook
  ];

  # 2. Setup Directories
  systemd.tmpfiles.rules =[
    "d /var/lib/quartz 0750 root root -"
  ];

  # --- 3. THE NATIVE WEBHOOK LISTENER ---
  systemd.services.webhook-quartz = {
    description = "Webhook receiver for Quartz";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.webhook}/bin/webhook -hooks /etc/webhook/hooks.json -port 9001";
      User = "root";
    };
  };

  # Define what the webhook does when Forgejo hits it
  environment.etc."webhook/hooks.json".text = builtins.toJSON[
    {
      id = "rebuild-quartz";
      execute-command = "/run/current-system/sw/bin/systemctl";
      pass-arguments-to-command =[
        { source = "string"; name = "start"; }
        { source = "string"; name = "build-quartz.service"; }
      ];
    }
  ];

  # --- 4. THE BUILD SERVICE ---
  systemd.services.build-quartz = {
    description = "Build Quartz Static Site from local Forgejo";
    
    path =[ pkgs.git pkgs.git-lfs pkgs.nodejs pkgs.rsync pkgs.bash pkgs.coreutils ];
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      # Make sure this file exists on your server and contains: FORGEJO_TOKEN="your_token_here"
      EnvironmentFile = "/var/lib/quartz/secrets.env"; 
    };

    script = ''
      QUARTZ_DIR="/var/lib/quartz"
      TEMP_CLONE="/tmp/obsidian-vault-clone"
      
      LOCAL_URL="http://127.0.0.1:${toString myConstants.services.forgejo.port}"
      PUBLIC_DOMAIN="${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}"

      export HOME="/var/lib/quartz"

      echo "Starting Quartz Build..."

      # --- CLOUDFLARE / AUTHENTIK BYPASS FIX ---
      # 1. Provide credentials for the local IP
      echo "machine 127.0.0.1 login quartz-builder password $FORGEJO_TOKEN" > $HOME/.netrc
      chmod 600 $HOME/.netrc

      # 2. Force Git and LFS to rewrite the public URL back to localhost
      git config --global url."$LOCAL_URL/".insteadOf "https://$PUBLIC_DOMAIN/"
      git config --global lfs.transfer.enableHrefRewrite true

      # Step 1: Initialize Quartz if missing
      if [ ! -d "$QUARTZ_DIR/node_modules" ]; then
        echo "Initializing Quartz Engine..."
        rm -rf "$QUARTZ_DIR/.git" "$QUARTZ_DIR/package.json" "$QUARTZ_DIR/package-lock.json"
        
        git clone https://github.com/jackyzha0/quartz.git /tmp/quartz-init
        cp -a /tmp/quartz-init/. "$QUARTZ_DIR/"
        rm -rf /tmp/quartz-init
        
        cd "$QUARTZ_DIR"
        npm install
      fi

      # Step 2: Clone the vault and pull LFS files
      rm -rf $TEMP_CLONE
      export GIT_LFS_SKIP_SMUDGE=1
      
      git clone "$LOCAL_URL/arthur-delannoy/obsidian.git" $TEMP_CLONE
      
      cd $TEMP_CLONE
      
      # Initialize LFS locally to remove the warning we saw in the test
      git lfs install --local
      git lfs pull --include="*.png,*.jpg,*.jpeg,*.gif,*.webp,*.svg"

      # Step 3: Sync to Quartz content directory
      echo "Syncing Markdown and Images to Quartz..."
      rsync -av --delete --exclude='.obsidian' $TEMP_CLONE/ $QUARTZ_DIR/content/

      # Step 4: Build the static site
      echo "Building Quartz..."
      cd $QUARTZ_DIR
      npx quartz build
      
      # Step 5: Clean up credentials for security
      rm -rf $TEMP_CLONE
      rm -f $HOME/.netrc
      rm -f $HOME/.gitconfig
      
      echo "Quartz build completed! Files are served by Caddy at /var/lib/quartz/public"
    '';
  };
}