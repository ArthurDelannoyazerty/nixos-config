{ config, pkgs, myConstants, ... }:

let
  # 1. SETTINGS
  settingsYaml = pkgs.writeText "settings.yaml" ''
    title: Arthur's Homelab
    background:
      image: https://images.unsplash.com/photo-1550684848-fac1c5b4e853?q=80&w=2070&auto=format&fit=crop
      opacity: 0.5
    layout:
      Finance:
        style: grid
        columns: 2
      Server:
        style: grid
        columns: 2

    providers:
      lldap:
        url: http://127.0.0.1:17171 # Talk to LLDAP via localhost
        bindDN: uid=admin,ou=people,dc=home,dc=arpa
        bindPassword: "adminpassword"
        searchDN: ou=people,dc=home,dc=arpa
        searchFilter: (uid={{user}})
  '';

  # 2. SERVICES
  servicesYaml = pkgs.writeText "services.yaml" ''
    - Services:
        - Finance:
            icon: mdi-cash-multiple
            href: https://${myConstants.services.finance.subdomain}.${myConstants.publicDomain}
            description: Streamlit Finance Tracker
            server: my-docker
            container: local-finance
        - Vikunja:
            icon: mdi-checkbox-marked-outline
            href: https://${myConstants.services.vikunja.subdomain}.${myConstants.publicDomain}
            description: To-Do & Projects
            server: my-docker
            container: vikunja

    - Server:
        - Netdata:
            icon: mdi-server-network
            href: https://${myConstants.services.netdata.subdomain}.${myConstants.publicDomain}
            description: System Monitor
        # - Filebrowser:
        #     icon: mdi-folder
        #     href: https://${myConstants.services.filebrowser.subdomain}.${myConstants.publicDomain}
        #     description: Manage Files
        - Scrutiny:
            icon: mdi-harddisk
            href: https://${myConstants.services.scrutiny.subdomain}.${myConstants.publicDomain}
            description: Disk Health
        - Power Costs:
            description: Estimated Power (W) & Cost (€/month)
            widget:
              type: customapi
              url: http://172.17.0.1:${toString myConstants.services.power-monitor.port}
              refresh: 2000
              mappings:
                - field: Usage
                  label: Power
                - field: Cost
                  label: Estimation
        - Settings & Auth:
            - Authentik Dashboard:
                icon: mdi-shield-account
                href: https://authentik.arthur-lab.com
                description: Manage Users
            - Switch User (Log Out):
                icon: mdi-logout
                # This uses the built-in logout route on your homepage domain
                href: https://homepage.arthur-lab.com/outpost.goauthentik.io/sign_out
                description: Terminate SSO Session
  '';

  # 3. BOOKMARKS: Empty list to remove the default "Developer/Social/Entertainment" links
  bookmarksYaml = pkgs.writeText "bookmarks.yaml" ''
    []
  '';

  # 4. DOCKER: Defines the connection to the host
  dockerYaml = pkgs.writeText "docker.yaml" ''
    my-docker:
      socket: tcp://172.17.0.1:2375
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

    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
  };
}