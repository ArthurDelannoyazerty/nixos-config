{ config, pkgs, myConstants, ... }:

let
  # Internal Docker Gateway IP
  internalHost = "http://172.17.0.1";

  # 1. SETTINGS & THEME
  settingsYaml = pkgs.writeText "settings.yaml" ''
    title: Homelab
    
    theme: dark
    color: stone

    headerStyle: boxed
    
    cardBlur: xl
    background:
      image: "linear-gradient(to bottom right, #0f172a, #1e293b, #172554)"
      opacity: 100

    # Set to false to hide the CPU/RAM bars on cards
    showStats: true
    statusStyle: dot 

    layout:
      Information:
        style: row
        columns: 4
      Productivity:
        style: row
        columns: 2
      Infrastructure:
        style: row
        columns: 2
      Monitoring:
        style: row
        columns: 2
  '';

  # 2. WIDGETS (Header)
  widgetsYaml = pkgs.writeText "widgets.yaml" ''
    - resources:
        expanded: true
        disk: 
          - /
          - /mnt/storage

    - resources:
        memory: true
        expanded: true

    - resources:
        cpu: true
    
    - resources:
        cputemp: true
        tempmin: 0
        tempmax: 100 
        units: metric
        
    - resources:
        uptime: true

    - datetime:
        text_size: xl
        # ADD THIS: Enforces the DD/MM/YYYY format
        locale: fr-FR 
        format:
            hour12: false
            # We explicitly define the units to ensure the exact HH:MM DD/MM/YYYY look
            hour: '2-digit'
            minute: '2-digit'
            day: '2-digit'
            month: '2-digit'
            year: 'numeric'
  '';

  # 3. SERVICES
  servicesYaml = pkgs.writeText "services.yaml" ''
    - Information:
        - Power Costs:
            description: Real-time Power
            icon: mdi-lightning-bolt
            widget:
              type: customapi
              url: ${internalHost}:${toString myConstants.services.power-monitor.port}
              refresh: 2000
              mappings:
                - field: Usage
                  label: Power
                  format: float
                  suffix: " W"
                - field: Cost
                  label: Monthly
                  format: float
                  prefix: "€"
        
        - Authentik:
            icon: authentik.png
            href: https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}
            description: Authentification
            siteMonitor: ${internalHost}:${toString myConstants.services.authentik.port}
            widget:
              type: authentik
              url: https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}
              key: ygODP16x2dZlpJGKpM2UB34nylQYBVHdnXsoXofrY3OWp8LzQl05ZDIYMwQk
              version: 2 # optional, default is 1
        
        - Log Out:
            icon: mdi-logout
            href: https://${myConstants.services.homepage.subdomain}.${myConstants.publicDomain}/outpost.goauthentik.io/sign_out
            description: End Session

    - Productivity:
        - Finance:
            icon: si-streamlit
            href: https://${myConstants.services.finance.subdomain}.${myConstants.publicDomain}
            description: Personal Finance Tracker
            siteMonitor: ${internalHost}:${toString myConstants.services.finance.port}
        
        - Vikunja:
            icon: vikunja.png
            href: https://${myConstants.services.vikunja.subdomain}.${myConstants.publicDomain}
            description: Tasks & Projects
            # Removed server/container to hide resource usage stats
            siteMonitor: ${internalHost}:${toString myConstants.services.vikunja.port}

    - Services:
        - Forgejo:
            icon: forgejo.png
            href: https://${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}
            description: Git Repositories
            siteMonitor: ${internalHost}:${toString myConstants.services.forgejo.port}

    - Monitoring:
        - Scrutiny:
            icon: scrutiny.png
            href: https://${myConstants.services.scrutiny.subdomain}.${myConstants.publicDomain}
            ping: https://${myConstants.services.scrutiny.subdomain}.${myConstants.publicDomain}
            description: Disks Health
            widget:
                type: scrutiny
                url: ${internalHost}:${toString myConstants.services.scrutiny.port}
        - Netdata:
            icon: netdata.png
            href: https://${myConstants.services.netdata.subdomain}.${myConstants.publicDomain}
            ping: https://${myConstants.services.netdata.subdomain}.${myConstants.publicDomain}
            description: Realtime Node Monitoring
            widget:
                type: netdata
                url: ${internalHost}:${toString myConstants.services.netdata.port}
        
        - Uptime Kuma:
            icon: uptime-kuma.png
            href: https://${myConstants.services.uptime-kuma.subdomain}.${myConstants.publicDomain}
            ping: https://${myConstants.services.uptime-kuma.subdomain}.${myConstants.publicDomain}
            description: Services Uptime
            widget:
                type: uptimekuma
                url: ${internalHost}:${toString myConstants.services.uptime-kuma.port}
                slug: default 
  '';

  # 4. BOOKMARKS
  bookmarksYaml = pkgs.writeText "bookmarks.yaml" ''
    []
  '';

  # 5. DOCKER
  dockerYaml = pkgs.writeText "docker.yaml" ''
    my-docker:
      host: 172.17.0.1
      port: 2375
    '';
in
{
  virtualisation.oci-containers.containers.homepage = {
    image = "ghcr.io/gethomepage/homepage:${myConstants.services.homepage.version}";
    ports = [ (myConstants.bind myConstants.services.homepage.port) ];
    
    environment = {
      HOMEPAGE_ALLOWED_HOSTS = "*"; 
      DOCKER_HOST = "tcp://172.17.0.1:2375";
    };

    volumes = [
      "${settingsYaml}:/app/config/settings.yaml"
      "${servicesYaml}:/app/config/services.yaml"
      "${widgetsYaml}:/app/config/widgets.yaml"
      "${dockerYaml}:/app/config/docker.yaml"
      "${bookmarksYaml}:/app/config/bookmarks.yaml" 
      "/mnt/storage:/mnt/storage:ro" # Read-only access to HDD so it can measure it
    ];

    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
  };
}