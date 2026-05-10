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

    showStats: false  # hide docker container stats on service cards
    statusStyle: dot 

    layout:
      Family:
        tab: Home
        columns: 2
      Media:
        tab: Home
        columns: 4
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
          - ${myConstants.paths.disk2TB}
          - ${myConstants.paths.disk4TB}
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
            description: Stockage Photos
            server: my-docker
            container: ${myConstants.services.immich.containerName}
            widget:
                type: immich
                url: ${internalHost}:${toString myConstants.services.immich.port}
                key: 1CcVvq9WjwqL1gL9j5O3qpbRI0nUCeNOscfAMK6HaYI
                version: 2
        - Vikunja:
            icon: vikunja.png
            href: https://${myConstants.services.vikunja.subdomain}.${myConstants.publicDomain}
            description: Tasks & Projects
            server: my-docker
            container: ${myConstants.services.vikunja.containerName}
        - FileBrowser Quantum:
            icon: filebrowser-quantum.svg
            href: https://${myConstants.services.filebrowser-quantum.subdomain}.${myConstants.publicDomain}
            description: Personal Cloud Storage
            server: my-docker
            container: ${myConstants.services.filebrowser-quantum.containerName}
        - Stirling PDF:
            icon: stirling-pdf.png
            href: https://${myConstants.services.stirling-pdf.subdomain}.${myConstants.publicDomain}
            description: PDF Manipulation Suite
            server: my-docker
            container: ${myConstants.services.stirling-pdf.containerName}
        - VERT Converter:
            icon: https://avatars.githubusercontent.com/u/198117259?s=200&v=4
            href: https://${myConstants.services.vert.subdomain}.${myConstants.publicDomain}
            description: File Converter
            server: my-docker
            container: ${myConstants.services.vert.containerName}

    - Media:
        - Jellyfin:
            icon: jellyfin.png
            href: https://${myConstants.services.jellyfin.subdomain}.${myConstants.publicDomain}
            description: Streaming Video
            server: my-docker
            container: ${myConstants.services.jellyfin.containerName}
            widget:
              type: jellyfin
              url: ${internalHost}:${toString myConstants.services.jellyfin.port}
              enable_now_playing: true # Shows what people are currently watching
        - Komga:
            icon: komga.png
            href: https://${myConstants.services.komga.subdomain}.${myConstants.publicDomain}
            description: Manga & Comics Reader
            server: my-docker
            container: ${myConstants.services.komga.containerName}
            widget:
              type: komga
              url: ${internalHost}:${toString myConstants.services.komga.port}
              username: admin # Komga widget needs auth
              password: password
          - Suwayomi:
            icon: suwayomi.png
            href: https://${myConstants.services.suwayomi.subdomain}.${myConstants.publicDomain}
            description: Manga Downloader
            server: my-docker
            container: ${myConstants.services.suwayomi.containerName}
            widget:
              type: suwayomi
              url: ${internalHost}:${toString myConstants.services.suwayomi.port}
        - Sonarr:
            icon: sonarr.png
            href: https://${myConstants.services.sonarr.subdomain}.${myConstants.publicDomain}
            description: Anime Management
            server: my-docker
            container: ${myConstants.services.sonarr.containerName}
            widget:
              type: sonarr
              url: ${internalHost}:${toString myConstants.services.sonarr.port}
              key: REPLACE_ME_WITH_SONARR_API_KEY
        - qBittorrent:
            icon: qbittorrent.png
            href: https://${myConstants.services.qbittorrent.subdomain}.${myConstants.publicDomain}
            description: Torrent Client
            server: my-docker
            container: ${myConstants.services.qbittorrent.containerName}
            widget:
              type: qbittorrent
              url: ${internalHost}:${toString myConstants.services.qbittorrent.port}
        - Prowlarr:
            icon: prowlarr.png
            href: https://${myConstants.services.prowlarr.subdomain}.${myConstants.publicDomain}
            description: Indexer Manager
            server: my-docker
            container: ${myConstants.services.prowlarr.containerName}

    - Authentification:
        - Authentik:
            icon: authentik.png
            href: https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}
            description: Authentification
            server: my-docker
            container: ${myConstants.services.authentik.containerName}
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
            server: my-docker
            container: ${myConstants.services.n8n.containerName}
        - RomM:
            icon: romm.png
            href: https://${myConstants.services.romm.subdomain}.${myConstants.publicDomain}
            description: Retro Game Manager
            server: my-docker
            container: ${myConstants.services.romm.containerName}
            widget:
              type: romm
              url: ${internalHost}:${toString myConstants.services.romm.port}
        - Obsidian Notes:
            icon: obsidian.png
            href: https://${myConstants.services.quartz.subdomain}.${myConstants.publicDomain}
            description: Digital Garden
        - Crafty Controller:
            icon: https://cdn.freebiesupply.com/logos/large/2x/minecraft-1-logo-png-transparent.png
            href: https://${myConstants.services.crafty-controller.subdomain}.${myConstants.publicDomain}
            description: Minecraft Server Manager
            server: my-docker
            container: ${myConstants.services.crafty-controller.containerName}
        - Wanderer:
            icon: mdi-map-marker-path
            href: https://${myConstants.services.wanderer.subdomain}.${myConstants.publicDomain}
            description: Trail & GPS Track Database
            server: my-docker
            container: ${myConstants.services.wanderer.containerName}

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
        - Scanopy:
            icon: https://scanopy.net/scanopy-logo-64.webp"
            href: https://${myConstants.services.scanopy.subdomain}.${myConstants.publicDomain}
            description: Network Inventory & Scanner
            server: my-docker
            container: ${myConstants.services.scanopy.containerName}
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
  virtualisation.oci-containers.containers.${myConstants.services.homepage.containerName} = {
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
      
      "${myConstants.paths.disk2TB}:${myConstants.paths.disk2TB}:ro"
      "${myConstants.paths.disk4TB}:${myConstants.paths.disk4TB}:ro"
    ];

    extraOptions = [ "--add-host=host.docker.internal:host-gateway" ];
  };
}