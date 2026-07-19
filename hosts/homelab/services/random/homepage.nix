{ config, pkgs, myConstants, ... }:

let
  # Internal Docker Gateway IP
  internalHost = "http://${myConstants.dockerSocketProxy}";

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
      Sauvegarde:
        tab: Public
        columns: 2
      Media:
        tab: Public
        columns: 2
      Autres:
        tab: Public
        columns: 2
      Authentification:
        tab: Public
        columns: 2
      Random:
        tab: Privé
        columns: 2
      Lecteur Médias:
        tab: Privé
        columns: 2
      Gestion Médias:
        tab: Privé
        columns: 2
      Monitoring:
        tab: Privé
        columns: 2
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
    - Sauvegarde:
        - Immich: 
            icon: immich.png
            href: https://${myConstants.services.immich.subdomain}.${myConstants.publicDomain}
            description: Archive Photos
            server: my-docker
            container: ${myConstants.services.immich.containerName}
            widget:
                type: immich
                url: ${internalHost}:${toString myConstants.services.immich.port}
                key: 1CcVvq9WjwqL1gL9j5O3qpbRI0nUCeNOscfAMK6HaYI
                version: 2
        - FileBrowser Quantum:
            icon: filebrowser-quantum.svg
            href: https://${myConstants.services.filebrowser-quantum.subdomain}.${myConstants.publicDomain}
            description: Stockage Fichiers
            server: my-docker
            container: ${myConstants.services.filebrowser-quantum.containerName}

    - Autres:
        - FreshRSS:
            icon: freshrss.png
            href: https://${myConstants.services.freshrss.subdomain}.${myConstants.publicDomain}
            description: News
            server: my-docker
            container: ${myConstants.services.freshrss.containerName}
        - Stirling PDF:
            icon: stirling-pdf.png
            href: https://${myConstants.services.stirling-pdf.subdomain}.${myConstants.publicDomain}
            description: Suite PDF
            server: my-docker
            container: ${myConstants.services.stirling-pdf.containerName}
        - VERT Converter:
            icon: https://avatars.githubusercontent.com/u/198117259?s=200&v=4
            href: https://${myConstants.services.vert.subdomain}.${myConstants.publicDomain}
            description: Conversion Images, Audio, Documents, Video 
            server: my-docker
            container: ${myConstants.services.vert.containerName}
        - Pub:
            icon: mdi-advertisements
            href: "#show-my-ad"
            description: Pub

    - Media:
        - Jellyfin:
            icon: jellyfin.png
            href: https://${myConstants.services.jellyfin.subdomain}.${myConstants.publicDomain}
            description: Streaming
            server: my-docker
            container: ${myConstants.services.jellyfin.containerName}
            widget:
              type: jellyfin
              url: ${internalHost}:${toString myConstants.services.jellyfin.port}
              key: "{{HOMEPAGE_VAR_JELLYFIN_KEY}}"
              enable_now_playing: true # Shows what people are currently watching
        - Seerr:
            icon: https://raw.githubusercontent.com/seerr-team/seerr/refs/heads/develop/public/os_icon.svg
            href: https://${myConstants.services.seerr.subdomain}.${myConstants.publicDomain}
            description: Requête Media
            server: my-docker
            container: ${myConstants.services.seerr.containerName}
            widget:
              type: seerr
              url: https://${myConstants.services.seerr.subdomain}.${myConstants.publicDomain}
              key: "{{HOMEPAGE_VAR_SEERR_KEY}}"
        # - Piped:
        #     icon: https://docs.piped.video/images/logo.svg
        #     href: https://${myConstants.services.piped-frontend.subdomain}.${myConstants.publicDomain}
        #     description: Requête Media
        #     server: my-docker
        #     container: ${myConstants.services.piped-frontend.containerName}
        - Komga:
            icon: komga.png
            href: https://${myConstants.services.komga.subdomain}.${myConstants.publicDomain}
            description: Lecteur Manga
            server: my-docker
            container: ${myConstants.services.komga.containerName}
            # widget:
            #   type: komga
            #   url: https://${myConstants.services.komga.subdomain}.${myConstants.publicDomain}
            #   username: "{{HOMEPAGE_VAR_KOMGA_USERNAME}}"
            #   password: "{{HOMEPAGE_VAR_KOMGA_PASSWORD}}"
            #   key: "{{HOMEPAGE_VAR_KOMGA_KEY}}"

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
            description: Se Deconnecter

    - Random:
        - Vikunja:
            icon: vikunja.png
            href: https://${myConstants.services.vikunja.subdomain}.${myConstants.publicDomain}
            description: TODO List
            server: my-docker
            container: ${myConstants.services.vikunja.containerName}
        - Firefox:
            icon: firefox.png
            href: https://${myConstants.services.firefox.subdomain}.${myConstants.publicDomain}
            description: Virtual Browser
            server: my-docker
            container: ${myConstants.services.firefox.containerName}
        - Finance:
            icon: si-streamlit
            href: https://${myConstants.services.finance.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.finance.port}
            description: Finances
        - Forgejo:
            icon: forgejo.png
            href: https://${myConstants.services.forgejo.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.forgejo.port}
            description: Forge Git
        - n8n:
            icon: n8n.png
            href: https://${myConstants.services.n8n.subdomain}.${myConstants.publicDomain}
            description: Worflows
            server: my-docker
            container: ${myConstants.services.n8n.containerName}
        - RomM:
            icon: romm.png
            href: https://${myConstants.services.romm.subdomain}.${myConstants.publicDomain}
            description: Retro Game Library and Emulator
            server: my-docker
            container: ${myConstants.services.romm.containerName}
            widget:
              type: romm
              url: ${internalHost}:${toString myConstants.services.romm.port}
        - Obsidian Notes:
            icon: obsidian.png
            href: https://${myConstants.services.quartz.subdomain}.${myConstants.publicDomain}
            description: Site Statique Obsidian Notes
        - Crafty Controller:
            icon: https://cdn.freebiesupply.com/logos/large/2x/minecraft-1-logo-png-transparent.png
            href: https://${myConstants.services.crafty-controller.subdomain}.${myConstants.publicDomain}
            description: Minecraft Server Manager
            server: my-docker
            container: ${myConstants.services.crafty-controller.containerName}
        - Wanderer:
            icon: mdi-map-marker-path
            href: https://${myConstants.services.wanderer.subdomain}.${myConstants.publicDomain}
            description: GPX Viewer
            server: my-docker
            container: ${myConstants.services.wanderer.containerName}


    - Gestion Médias:
        - AriaNg:
            icon: https://play-lh.googleusercontent.com/c2cc3NnGBdVdH4JNaW4HXJLTDXFtSk9No0u2BJOV5ya3YlOrygE3JEdNOhd4Xf9pUPI=w240-h480-rw
            href: https://${myConstants.services.ariang.subdomain}.${myConstants.publicDomain}
            description: Download Manager
            server: my-docker
            container: ${myConstants.services.ariang.containerName}
        - Suwayomi:
            icon: suwayomi.png
            href: https://${myConstants.services.suwayomi.subdomain}.${myConstants.publicDomain}
            description: Manga Downloader
            server: my-docker
            container: ${myConstants.services.suwayomi.containerName}
            # widget:
            #   type: suwayomi
            #   url: ${internalHost}:${toString myConstants.services.suwayomi.port}
        - Tranga: 
            icon: mdi-book-open-page-variant
            href: https://${myConstants.services.tranga.subdomain}.${myConstants.publicDomain}
            description: Manga Downloader
            server: my-docker
            container: ${myConstants.services.tranga.containerName}
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
            description: Indexers
            server: my-docker
            container: ${myConstants.services.prowlarr.containerName}
        - Sonarr:
            icon: sonarr.png
            href: https://${myConstants.services.sonarr.subdomain}.${myConstants.publicDomain}
            description: Anime Backend Downloader
            server: my-docker
            container: ${myConstants.services.sonarr.containerName}
            widget:
              type: sonarr
              url: ${internalHost}:${toString myConstants.services.sonarr.port}
              key: "{{HOMEPAGE_VAR_SONARR_KEY}}"
        - Byparr:
            icon: https://raw.githubusercontent.com/ThePhaseless/Byparr/557152ccdcf32025b77438ab51c93f58eb284980/icon/logo-byparr.svg
            href: https://${myConstants.services.byparr.subdomain}.${myConstants.publicDomain}/docs
            description: Cloudflare Bypass
            server: my-docker
            container: ${myConstants.services.byparr.containerName}
        - Recyclarr:
            icon: https://recyclarr.dev/img/recyclarr.png
            description: Media Profiles 
            server: my-docker
            container: ${myConstants.services.recyclarr.containerName}
        - Cleanuparr:
            icon: https://raw.githubusercontent.com/Cleanuparr/Cleanuparr/refs/heads/main/Logo/256.png
            href: https://${myConstants.services.cleanuparr.subdomain}.${myConstants.publicDomain}
            description: Storage Cleanup Manager
            server: my-docker
            container: ${myConstants.services.cleanuparr.containerName}

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
            description: Server Dashboard
        - Netdata:
            icon: netdata.png
            href: https://${myConstants.services.netdata.subdomain}.${myConstants.publicDomain}
            siteMonitor: ${internalHost}:${toString myConstants.services.netdata.port}
            description: Server Usage Monitoring
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
            highlight:
                down:
                    numeric:
                        - level: danger
                          when: gt
                          value: 0
        - Borgmatic Backups:
            icon: mdi-database-check
            href: https://${myConstants.services.uptime-kuma.subdomain}.${myConstants.publicDomain}/status/borg-backups
            description: Nightly Backups
            id: borg-backups
            widget:
                type: uptimekuma
                url: ${internalHost}:${toString myConstants.services.uptime-kuma.port}
                slug: borg-backups
        - Scanopy:
            icon: https://scanopy.net/scanopy-logo-64.webp
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
      host: socket-proxy
      port: 2375
    '';


# 6. CUSTOM JS (The Joke Advertisement & Resilient Borgmatic Check)
  customJs = pkgs.writeText "custom.js" ''
    console.log("--- HOMEPAGE CUSTOM JS LOADED SUCCESSFULLY ---");

    // --- Borgmatic Status Check ---
    function checkBorgmaticStatus() {
        // Find the service card
        const card = document.getElementById('borg-backups');
        if (!card) {
            console.warn("[Borgmatic Check] Element with ID 'borg-backups' not found on page.");
            return;
        }

        // Grabbing the overall text content to avoid targeting specific HTML tags (div vs span)
        const text = card.textContent.toUpperCase();
        
        // Match numbers preceding 'SITES DOWN' or 'SITE DOWN'
        const match = text.match(/(\d+)\s*SITES?\s*DOWN/);
        
        if (match) {
            const downCount = parseInt(match[1], 10);
            console.log("[Borgmatic Check] Detected Sites Down count via regex: " + downCount);

            if (downCount >= 1) {
                console.log("[Borgmatic Check] State is FAIL. Applying red card background.");
                card.classList.add('card-danger-bg');
            } else {
                card.classList.remove('card-danger-bg');
            }
        } else {
            console.warn("[Borgmatic Check] 'SITES DOWN' pattern not yet rendered on the page.");
        }
    }

    // Safely boot scheduler even if document is already interactive/complete
    function initBorgmaticScheduler() {
        console.log("[Borgmatic Check] Starting interval loop (3s)...");
        setInterval(checkBorgmaticStatus, 3000);
        checkBorgmaticStatus(); // Run first check immediately
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initBorgmaticScheduler);
    } else {
        initBorgmaticScheduler();
    }

    // --- The Joke Advertisement ---
    document.addEventListener('click', function(event) {
        const target = event.target.closest('a');
        
        if (target && target.getAttribute('href') === '#show-my-ad') {
            event.preventDefault(); 
            
            // Prevent spawning multiple popups
            if (document.getElementById('my-cool-popup')) return;

            const popupOverlay = document.createElement('div');
            popupOverlay.id = 'my-cool-popup';
            
            popupOverlay.innerHTML = `
                <style>
                    #my-cool-popup {
                        position: fixed;
                        top: 0; left: 0; width: 100vw; height: 100vh;
                        background: rgba(0,0,0,0.85);
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        z-index: 999999;
                    }
                    .popup-box {
                        position: relative !important;
                        z-index: 1 !important;
                        overflow: hidden !important;
                        
                        padding: 60px !important;
                        border: 10px solid white !important;
                        border-radius: 20px !important;
                        box-shadow: 0 0 100px rgba(255,255,255,0.4) !important;
                        transform: rotate(-10deg) !important;
                        text-align: center !important;
                        max-width: 90% !important;
                        display: flex !important;
                        flex-direction: column !important;
                        align-items: center !important;
                    }
                    
                    .popup-box::before {
                        content: "" !important;
                        position: absolute !important;
                        top: 0 !important; left: 0 !important; 
                        width: 100% !important; height: 100% !important;
                        z-index: -1 !important;
                        animation: bgBlink 0.4s infinite !important;
                    }

                    @keyframes bgBlink {
                        0%, 49% { 
                            background: repeating-linear-gradient(-45deg, yellow, yellow 30px, violet 30px, violet 60px); 
                        }
                        50%, 100% { 
                            background: repeating-linear-gradient(-45deg, violet, violet 30px, yellow 30px, yellow 60px); 
                        }
                    }

                    .blinking-title {
                        display: block !important;
                        font-family: "Comic Sans MS", "Comic Sans", cursive !important;
                        font-size: 4rem !important;
                        font-weight: 900 !important;
                        line-height: 1.2 !important;
                        margin: 0 0 30px 0 !important;
                        text-transform: uppercase !important;
                        
                        color: black !important; 
                        text-shadow: 4px 4px 0px white !important;
                        
                        animation: epicBlink 0.4s infinite !important;
                    }
                    
                    @keyframes epicBlink {
                        0%, 49% { filter: invert(0%); }
                        50%, 100% { filter: invert(100%); }
                    }

                    .dismiss-btn {
                        background: black !important;
                        color: white !important;
                        border: 4px solid white !important;
                        padding: 15px 40px !important;
                        font-family: "Comic Sans MS", "Comic Sans", cursive !important;
                        font-size: 2rem !important;
                        font-weight: bold !important;
                        cursor: pointer !important;
                        border-radius: 10px !important;
                        box-shadow: 5px 5px 0px white !important;
                        transition: transform 0.1s !important;
                        display: inline-block !important;
                    }
                    .dismiss-btn:hover {
                        background: white !important;
                        color: black !important;
                        border-color: black !important;
                        box-shadow: 5px 5px 0px black !important;
                        transform: scale(1.1) !important;
                    }
                </style>
                <div class="popup-box">
                    <div class="blinking-title">Venez visiter<br>le serveur !</div>
                    <button id="close-cool-popup" class="dismiss-btn">Fermer</button>
                </div>
            `;

            document.body.appendChild(popupOverlay);

            document.getElementById('close-cool-popup').addEventListener('click', function() {
                popupOverlay.remove();
            });
        }
    });
  '';

# 7. CUSTOM CSS (Borgmatic Warning Background)
  customCss = pkgs.writeText "custom.css" ''
    /* Main card container alert styling */
    .card-danger-bg {
        background-color: rgba(220, 38, 38, 0.35) !important; 
        border: 2px solid rgba(220, 38, 38, 0.9) !important;
        animation: pulseAlert 2.5s infinite ease-in-out;
    }

    /* Force nested structural wrappers to be transparent so our red background is visible */
    .card-danger-bg > div,
    .card-danger-bg > a {
        background-color: transparent !important;
        border-color: transparent !important;
    }

    /* Subtle pulsing effect for high visibility */
    @keyframes pulseAlert {
        0%, 100% {
            box-shadow: 0 0 4px rgba(220, 38, 38, 0.3);
        }
        50% {
            box-shadow: 0 0 16px rgba(220, 38, 38, 0.7);
        }
    }
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

    environmentFiles = [
      "/var/lib/homepage/secrets.env"
    ];

    volumes = [
      "${settingsYaml}:/app/config/settings.yaml"
      "${servicesYaml}:/app/config/services.yaml"
      "${widgetsYaml}:/app/config/widgets.yaml"
      "${dockerYaml}:/app/config/docker.yaml"
      "${bookmarksYaml}:/app/config/bookmarks.yaml" 

      # Custom JS 
      "${customJs}:/app/config/custom.js"
      
      # Custom CSS
      "${customCss}:/app/config/custom.css"
      
      "${myConstants.paths.disk2TB}:${myConstants.paths.disk2TB}:ro"
      "${myConstants.paths.disk4TB}:${myConstants.paths.disk4TB}:ro"
    ];

    extraOptions = [ 
        "--add-host=host.docker.internal:host-gateway" 
        "--link=socket-proxy:socket-proxy"
    ];
  };
}