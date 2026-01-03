{ config, pkgs, ... }:

let
  port = 3000;

  # Define configuration files as variables
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

  servicesYaml = pkgs.writeText "services.yaml" ''
    - Finance:
        - My Finance:
            icon: mdi-cash-multiple
            # Link for the browser (use hostname or IP)
            href: http://${config.networking.hostName}:8501
            description: Streamlit Finance Tracker
            server: my-docker
            container: local-finance
            widget:
              type: customapi
              # Link for the Homepage container to fetch stats
              # We use the docker bridge IP (172.17.0.1) to talk to the host
              url: http://172.17.0.1:8501/_stcore/health
              method: GET

    - Server:
        - System Stats:
            widget:
              type: resources
              cpu: true
              memory: true
              disk: /
  '';

  dockerYaml = pkgs.writeText "docker.yaml" ''
    my-docker:
      socket: /var/run/docker.sock
  '';
in
{
  # Open Firewall
  networking.firewall.allowedTCPPorts = [ 80 ];

  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    ports = [ "80:${toString port}" ];
    volumes = [
      # Mount the Nix store paths directly to the container paths
      "${settingsYaml}:/app/config/settings.yaml"
      "${servicesYaml}:/app/config/services.yaml"
      "${dockerYaml}:/app/config/docker.yaml"
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
  };
}