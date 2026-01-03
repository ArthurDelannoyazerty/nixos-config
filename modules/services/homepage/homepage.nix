{ config, pkgs, ... }:

let
  port = 3000;

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

    - Server:
        - System Stats:
            icon: mdi-server
            # We link this card to the 'my-docker' socket defined in docker.yaml
            server: my-docker 
            widget:
              type: resources
              cpu: true
              memory: true
              disk: /
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