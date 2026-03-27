{ config, pkgs, myConstants, ... }:

{
  # 1. Provide dependencies
  environment.systemPackages = with pkgs;[
    nodejs
    git
    git-lfs
    rsync
  ];

  # 2. Setup Directories
  systemd.tmpfiles.rules =[
    "d /var/lib/quartz 0750 root root -"
  ];

  # 3. Allow n8n (via SSH) to trigger the build securely
  security.sudo.extraRules = [
    {
      users = [ "arthur-homelab" ]; 
      commands =[
        {
          command = "/run/current-system/sw/bin/systemctl start build-quartz.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # 4. The Build Service
  systemd.services.build-quartz = {
    description = "Build Quartz Static Site from local Forgejo (with LFS)";
    
    # Add git-lfs to the execution path!
    path =[ pkgs.git pkgs.git-lfs pkgs.nodejs pkgs.rsync ];
    
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      # Read the secure token from this file at runtime
      EnvironmentFile = "/var/lib/quartz/secrets.env";
    };

    script = ''
      QUARTZ_DIR="/var/lib/quartz"
      TEMP_CLONE="/tmp/obsidian-vault-clone"
      
      # Use the FORGEJO_TOKEN injected securely by systemd EnvironmentFile
      # Replace YOUR_USER and YOUR_REPO below
      VAULT_URL="http://quartz-builder:$FORGEJO_TOKEN@127.0.0.1:${toString myConstants.services.forgejo.port}/arthur-delannoy/obsidian.git"

      # Step 1: Initialize Quartz if missing
      if[ ! -d "$QUARTZ_DIR/.git" ]; then
        git clone https://github.com/jackyzha0/quartz.git $QUARTZ_DIR
        cd $QUARTZ_DIR
        npm install
      fi

      # Step 2: Clone the vault and pull LFS files
      rm -rf $TEMP_CLONE
      
      # Tell git to use LFS in this temporary environment
      git lfs install
      
      # Clone the repository
      git clone $VAULT_URL $TEMP_CLONE
      
      # Enter the clone and explicitly pull all large files (images/PDFs)
      cd $TEMP_CLONE
      git lfs pull

      # Step 3: Sync to Quartz content directory
      # We exclude .git, but KEEP the images and markdown!
      rsync -av --delete --exclude='.git' --exclude='.obsidian' $TEMP_CLONE/ $QUARTZ_DIR/content/

      # Step 4: Build the site
      cd $QUARTZ_DIR
      npx quartz build
      
      # Clean up the temp clone so it doesn't waste disk space
      rm -rf $TEMP_CLONE
    '';
  };
}