{ config, pkgs, ... }:

let
  port = 3000;
  glancesPort = 61208;

  # 1. SETTINGS
  settingsYaml = pkgs.writeText "settings.yaml" ''
    title: Arthur's Homelab
    background:
      image: https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2070&auto=format&fit=crop
      opacity: 0.5
    layout:
      Finance:
        style: row
        columns: 2
      Server:
        style: row
        columns: 2
  '';

  # 2. SERVICES
  servicesYaml = pkgs.writeText "services.yaml" ''
    - Finance:
        - My Finance:
            icon: mdi-cash-multiple
            href: http://${config.networking.hostName}:8501
            description: Streamlit Finance Tracker
            server: my-docker
            container: local-finance

    - Productivity:
        - Vikunja:
            icon: mdi-checkbox-marked-outline
            href: http://${config.networking.hostName}:${toString vikunjaPort}
            description: To-Do & Projects
            server: my-docker
            container: vikunja
            widget:
                type: vikunja
                url: http://${config.networking.hostName}:${toString vikunjaPort}
                # To make the widget work, you'll need an API token from Vikunja later
                # key: YOUR_API_KEY 

    - Server:
        - Glances:
            icon: mdi-server-network
            href: http://${config.networking.hostName}:${toString glancesPort}
            description: Htop view
            server: my-docker 
        - Power Costs:
            description: Estimated Power (W) & Cost (€/month)
            widget:
              type: customapi
              url: http://${config.networking.hostName}:9100
              refresh: 2000 # Refresh every 2 seconds
              # Map the fields we defined in Python
              mappings:
                - field: Usage
                  label: Power
                - field: Cost
                  label: Estimation
  '';

  # 3. BOOKMARKS: Empty list to remove the default "Developer/Social/Entertainment" links
  bookmarksYaml = pkgs.writeText "bookmarks.yaml" ''
    []
  '';

  # 4. DOCKER: Defines the connection to the host
  dockerYaml = pkgs.writeText "docker.yaml" ''
    my-docker:
      socket: /var/run/docker.sock
  '';
in
{
  networking.firewall.allowedTCPPorts = [ 80 ];

  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    ports = [ "80:${toString port}" ];
    
    environment = {
      HOMEPAGE_ALLOWED_HOSTS = "*"; 
    };

    volumes = [
      "${settingsYaml}:/app/config/settings.yaml"
      "${servicesYaml}:/app/config/services.yaml"
      "${dockerYaml}:/app/config/docker.yaml"
      # Mount the empty bookmarks file
      "${bookmarksYaml}:/app/config/bookmarks.yaml" 
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
  };
}