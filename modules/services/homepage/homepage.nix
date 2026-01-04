{ config, pkgs, myConstants, ... }:

let
  domain = myConstants.domain; 
  
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
    - Services:
        - My Finance:
            icon: mdi-cash-multiple
            href: https://${myConstants.services.finance.subdomain}.${domain}
            description: Streamlit Finance Tracker
            server: my-docker
            container: local-finance
        - Vikunja:
            icon: mdi-checkbox-marked-outline
            href: https://${myConstants.services.vikunja.subdomain}.${domain}
            description: To-Do & Projects
            server: my-docker
            container: vikunja

    - Server:
        - Glances:
            icon: mdi-server-network
            href: https://${myConstants.services.glances.subdomain}.${domain}
            description: Htop view
            server: my-docker 
        - Netdata:
            icon: mdi-chart-line
            href: https://${myConstants.services.netdata.subdomain}.${domain}
        - Power Costs:
            description: Estimated Power (W) & Cost (€/month)
            widget:
              type: customapi
              # url internal because not publicly exposed
              url: http://172.17.0.1:${toString myConstants.services.power-monitor.port}
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
  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:${myConstants.services.homepage.version}";
    ports = [ (myConstants.bind myConstants.services.homepage.port) ];
    
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