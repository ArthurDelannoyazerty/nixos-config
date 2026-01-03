{ config, pkgs, ... }:

let
  port = 3000;
in
{
  # 1. Open the Firewall for this service
  networking.firewall.allowedTCPPorts = [ 80 ];

  # 2. Configure the Container
  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:latest";
    ports = [ "80:${toString port}" ];
    volumes = [
      "/etc/homepage:/app/config" 
      "/var/run/docker.sock:/var/run/docker.sock" 
    ];
  };

  # 3. Generate Configuration Files
  environment.etc."homepage/settings.yaml".text = ''
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

  environment.etc."homepage/services.yaml".text = ''
    - Finance:
        - My Finance:
            icon: mdi-cash-multiple
            href: http://${config.networking.hostName}:8501
            description: Streamlit Finance Tracker
            server: my-docker
            container: local-finance
            widget:
              type: customapi
              url: http://${config.networking.hostName}:8501/_stcore/health
              method: GET

    - Server:
        - System Stats:
            widget:
              type: resources
              cpu: true
              memory: true
              disk: /
  '';
  
  environment.etc."homepage/docker.yaml".text = ''
    my-docker:
      socket: /var/run/docker.sock
  '';
}