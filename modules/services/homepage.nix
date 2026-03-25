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

    showStats: true
    statusStyle: dot 

    layout:
      Family:
        tab: Home
        columns: 2
      Authentification:
        tab: Home
        columns: 2
      Other Services:
        tab: Home
        columns: 4
      Monitoring:
        tab: Server
        style: row
        columns: 4
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
        locale: fr-FR 
        format:
            hour12: false
            hour: '2-digit'
            minute: '2-digit'
            day: '2-digit'
            month: '2-digit'
            year: 'numeric'
  '';

  # 3. SERVICES
  servicesYaml = pkgs.writeText "services.yaml" ''
    - Family:
        - Immich: 
            icon: immich.png
            href: https://${myConstants.services.immich.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.immich.port}
            description: Stockage Photos
            widget:
                type: immich
                url: http://172.17.0.1:${toString myConstants.services.immich.port}
                key: 1CcVvq9WjwqL1gL9j5O3qpbRI0nUCeNOscfAMK6HaYI
                version: 2
        - Vikunja:
            icon: vikunja.png
            href: https://${myConstants.services.vikunja.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.vikunja.port}
            description: Tasks & Projects

    - Authentification:
        - Authentik:
            icon: authentik.png
            href: https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.authentik.port}
            description: Authentification
            widget:
              type: authentik
              url: https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}
              key: ygODP16x2dZlpJGKpM2UB34nylQYBVHdnXsoXofrY3OWp8LzQl05ZDIYMwQk
              version: 2
        - Log Out:
            icon: mdi-logout
            href: https://${myConstants.services.homepage.subdomain}.${myConstants.publicDomain}/outpost.goauthentik.io/sign_out
            description: End Session

    - Other Services:
        - Finance:
            icon: si-streamlit
            href: https://${myConstants.services.finance.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.finance.port}
            description: Personal Finance Tracker
        - Forgejo:
            icon: forgejo.png
            href: https://${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.forgejo.port}
            description: Git Repositories
        - n8n:
            icon: n8n.png
            href: https://${myConstants.services.n8n.subdomain}.${myConstants.publicDomain}
            description: Worflow Automation
        - RomM:
            icon: romm.png
            href: https://${myConstants.services.romm.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.romm.port}
            description: Retro Game Manager
            widget:
              type: romm
              url: ${internalHost}:${toString myConstants.services.romm.port}
        - FileBrowser Quantum:
            icon: filebrowser-quantum.svg
            href: https://${myConstants.services.filebrowser-quantum.subdomain}.${myConstants.publicDomain}
            description: Personal Cloud Storage
            server: my-docker
            container: ${myConstants.services.filebrowser-quantum.containerName}
        - Paperless NGX:
            icon: paperless.png
            href: https://${myConstants.services.paperless-ngx.subdomain}.${myConstants.publicDomain}
            siteMonitor: http://172.17.0.1:${toString myConstants.services.paperless-ngx.port}
            description: Document Management
            widget:
                type: paperlessngx
                url: http://172.17.0.1:${toString myConstants.services.paperless-ngx.port}
                key: YOUR_PAPERLESS_API_TOKEN

    - Monitoring:
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
        - Scrutiny:
            icon: scrutiny.png
            href: https://${myConstants.services.scrutiny.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.scrutiny.port}
            description: Disks Health
            widget:
                type: scrutiny
                url: ${internalHost}:${toString myConstants.services.scrutiny.port}
        - Grafana:
            icon: grafana.png
            href: https://${myConstants.services.grafana.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.grafana.port}
            description: Long-term Metrics Dashboard
        - Netdata:
            icon: netdata.png
            href: https://${myConstants.services.netdata.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.netdata.port}
            description: Realtime Node Monitoring
            widget:
                type: netdata
                url: ${internalHost}:${toString myConstants.services.netdata.port}
        - Uptime Kuma:
            icon: uptime-kuma.png
            href: https://${myConstants.services.uptime-kuma.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.uptime-kuma.port}
            description: Services Uptime
            widget:
                type: uptimekuma
                url: ${internalHost}:${toString myConstants.services.uptime-kuma.port}
                slug: default 
  '';

  # 4. BOOKMARKS - Unchanged
  bookmarksYaml = pkgs.writeText "bookmarks.yaml" ''
    []
  '';

  # 5. DOCKER - Unchanged
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
      "/mnt/storage:/mnt/storage:ro"
    ];

    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
  };
}