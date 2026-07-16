{ config, pkgs, myConstants, ... }:

let
  # --- SECURITY WATCHDOG FOR CADDY ---
  # Only allow requests from:
  # - 127.0.0.1/32 (The Cloudflare Tunnel daemon running locally)
  # - Your local LAN IP ranges (192.168.0.0/16, etc.)
  # - Your Tailscale network (100.64.0.0/10)
  # Any direct external scan to your router's open ports targeting private domains will be dropped with a 403.
  privateOnly = ''
    @untrusted {
      not remote_ip 127.0.0.1 ::1 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 100.64.0.0/10 fc00::/7 fe80::/10
    }
    respond @untrusted "Access Denied" 403
  '';

  authentikMiddleware = ''
    # A. Handle Authentik Outpost (Bypass Auth)
    handle /outpost.goauthentik.io/* {
      reverse_proxy 172.17.0.1:${toString myConstants.services.authentik.port}
    }

    # B. Auth Check (Forward to Authentik)
    forward_auth 127.0.0.1:${toString myConstants.services.authentik.port} {
      uri /outpost.goauthentik.io/auth/caddy
      # Copy user details so apps (like Vikunja/Finance) know who logged in
      copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jw Remote-User Remote-Email Remote-Name Remote-Groups
      header_up Host {host}
    }

    # C. Redirect to Login if Unauthorized (401)
    handle_errors {
      @401 expression {err.status_code} == 401
      handle @401 {
        redir https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/outpost.goauthentik.io/start?rd={request.uri}
      }
    }
  '';

  # Helper to make the config shorter
  domain = myConstants.publicDomain;
in
{
  services.caddy = {
    enable = true;

    dataDir = "${myConstants.paths.servicesSSD}/caddy";

    # Trust Cloudflare IPs so headers like {remote} give the real user IP, not Cloudflare's IP
    globalConfig = ''
      servers {
        trusted_proxies static private_ranges
      }
    '';

    virtualHosts = {
      
      # --- ROOT REDIRECT ---
      "http://${domain}" = {
        extraConfig = ''
          redir https://${myConstants.services.homepage.subdomain}.${domain} permanent
        '';
      };

      # --- AUTHENTIK ITSELF (Protected from direct public access) ---
      "http://${myConstants.services.authentik.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.authentik.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto https
          }
        '';
      };

      # --- HOMEPAGE (Protected from direct public access) ---
      "http://${myConstants.services.homepage.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware} # Inject the auth logic
          reverse_proxy 172.17.0.1:${toString myConstants.services.homepage.port}
        '';
      };

      # --- FINANCE (Protected from direct public access) ---
      "http://${myConstants.services.finance.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.finance.port}
        '';
      };

      # --- FIREFOX (Protected from direct public access) ---
      "http://${myConstants.services.firefox.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          
          reverse_proxy 172.17.0.1:${toString myConstants.services.firefox.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
          }
        '';
      };

      # --- JELLYFIN ---
      "${myConstants.services.jellyfin.subdomain}.${domain}" = {
        extraConfig = ''
          log

          # 1. Block accidental Cloudflare Proxy traffic (saving your CF account)
          @cloudflare {
            header Cf-Ray *
          }
          respond @cloudflare "Streaming via Cloudflare is disabled. Please connect directly." 403

          # 2. Pass to Jellyfin
          reverse_proxy 172.17.0.1:${toString myConstants.services.jellyfin.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto {scheme}
          }
        '';
      };

      # --- ARIANG ---
      "http://${myConstants.services.ariang.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          
          # 1. RPC endpoint bypasses Authentik (Secured internally by ARIA2_RPC_SECRET)
          handle /jsonrpc* {
            reverse_proxy 172.17.0.1:${toString myConstants.services.ariang.rpc-port}
          }

          # 2. The main Web UI is protected by Authentik Forward Auth
          handle {
            ${authentikMiddleware}
            reverse_proxy 172.17.0.1:${toString myConstants.services.ariang.port}
          }
        '';
      };

      # --- VIKUNJA (Protected from direct public access) ---
      "http://${myConstants.services.vikunja.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.vikunja.port} 
        '';
      };

      # --- ONLYOFFICE (Protected from direct public access) ---
      "http://${myConstants.services.onlyoffice.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}

          @blocked path / /welcome* /example*
          handle @blocked {
            respond "404 Not Found" 404
          }

          reverse_proxy 172.17.0.1:${toString myConstants.services.onlyoffice.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto https
            header_up X-Forwarded-Host {host}
          }
        '';
      };

      # --- STIRLING PDF (Protected from direct public access) ---
      "http://${myConstants.services.stirling-pdf.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.stirling-pdf.port}
        '';
      };

      # --- VERT FRONTEND (Protected from direct public access) ---
      "http://${myConstants.services.vert.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.vert.port}
        '';
      };

      # --- CRAFTY CONTROLLER (Protected from direct public access) ---
      "http://${myConstants.services.crafty-controller.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          
          reverse_proxy https://127.0.0.1:${toString myConstants.services.crafty-controller.port} {
            transport http {
              tls_insecure_skip_verify
              versions 1.1
            }
            header_up Upgrade websocket
            header_up Connection Upgrade
            header_up X-Forwarded-Proto https
            header_up X-Forwarded-For {remote}
            header_up Host {host}
          }
        '';
      };

      # --- SUWAYOMI (Protected from direct public access) ---
      "http://${myConstants.services.suwayomi.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.suwayomi.port}
        '';
      };

      # --- CLEANUPARR (Protected from direct public access) ---
      "http://${myConstants.services.cleanuparr.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.cleanuparr.port}
        '';
      };

      # --- KOMGA (Protected from direct public access) ---
      "http://${myConstants.services.komga.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.komga.port}
        '';
      };

      # --- BYPARR (Protected from direct public access) ---
      "http://${myConstants.services.byparr.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.byparr.port}
        '';
      };

      # --- TRANGA (Protected from direct public access) ---
      "http://${myConstants.services.tranga.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.tranga.port}
        '';
      };

      # --- QBITTORRENT (Protected from direct public access) ---
      "http://${myConstants.services.qbittorrent.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.qbittorrent.port} {
            header_up Host {host}
            header_up X-Forwarded-Host {host}
            header_up X-Forwarded-For {remote}
          }
        '';
      };

      # --- PROWLARR (Protected from direct public access) ---
      "http://${myConstants.services.prowlarr.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.prowlarr.port}
        '';
      };

      # --- SEERR (Protected from direct public access) ---
      "http://${myConstants.services.seerr.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.seerr.port}
        '';
      };

      # --- SONARR (Protected from direct public access) ---
      "http://${myConstants.services.sonarr.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.sonarr.port}
        '';
      };

      # --- QUARTZ (Protected from direct public access) ---
      "http://${myConstants.services.quartz.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware} 
          
          # Serve the static HTML files generated by Quartz
          root * ${myConstants.paths.servicesSSD}/quartz/public
          
          # Handle "Pretty URLs" (try the path, then path.html, then path/index.html)
          try_files {path} {path}.html {path}/index.html

          file_server
        '';
      };

      # --- FRESHRSS ---
      "http://${myConstants.services.freshrss.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          
          # Native OIDC is used here, so we don't apply authentikMiddleware
          reverse_proxy 172.17.0.1:${toString myConstants.services.freshrss.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto https
            header_up X-Forwarded-Host {host}
            header_up X-Forwarded-Port 443
          }
        '';
      };

      # --- PIPED FRONTEND (UI - Protected by Authentik) ---
      "http://${myConstants.services.piped-frontend.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.piped-frontend.port}
        '';
      };

      # --- PIPED API (Must bypass Authentik so the JS player can reach it) ---
      "http://${myConstants.services.piped-backend.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.piped-backend.port}
        '';
      };

      # --- PIPED PROXY (Must bypass Authentik so streams can be fetched) ---
      "http://${myConstants.services.piped-proxy.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.piped-proxy.port}
        '';
      };
      

      # --- GLANCES (Protected from direct public access) ---
      "http://${myConstants.services.glances.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.glances.port}
        '';
      };

      # --- FILEBROWSER (Protected from direct public access) ---
      "http://${myConstants.services.filebrowser.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.filebrowser.port}
        '';
      };

      # --- FILEBROWSER QUANTUM (Protected from direct public access) ---
      "http://${myConstants.services.filebrowser-quantum.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.filebrowser-quantum.port}
        '';
      };

      # --- N8N (Protected from direct public access) ---
      "http://${myConstants.services.n8n.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          
          # 1. Allow external webhooks to bypass Authentik SSO
          handle /webhook/* {
            reverse_proxy 172.17.0.1:${toString myConstants.services.n8n.port}
          }

          # 2. Protect the rest of the n8n UI with Authentik
          handle {
            # A. Handle Authentik Outpost (Bypass Auth)
            handle /outpost.goauthentik.io/* {
              reverse_proxy 172.17.0.1:${toString myConstants.services.authentik.port}
            }

            # B. Auth Check (Forward to Authentik)
            forward_auth 127.0.0.1:${toString myConstants.services.authentik.port} {
              uri /outpost.goauthentik.io/auth/caddy
              copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jw Remote-User Remote-Email Remote-Name Remote-Groups
              header_up Host {host}
            }
            
            # C. Actually proxy to n8n
            reverse_proxy 172.17.0.1:${toString myConstants.services.n8n.port}
          }

          # 3. Redirect to Login if Unauthorized (401) - MUST BE OUTSIDE `handle`
          handle_errors {
            @401 expression {err.status_code} == 401
            handle @401 {
              redir https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/outpost.goauthentik.io/start?rd={request.uri}
            }
          }
        '';
      };

      # --- ROMM (Protected from direct public access) ---
      "http://${myConstants.services.romm.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.romm.port}
        '';
      };

      # --- GRAFANA (Protected from direct public access) ---
      "http://${myConstants.services.grafana.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.grafana.port}
        '';
      };

      # --- SCRUTINY (Protected from direct public access) ---
      "http://${myConstants.services.scrutiny.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.scrutiny.port}
        '';
      };

      # --- UPTIME KUMA (Protected from direct public access) ---
      "http://${myConstants.services.uptime-kuma.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.uptime-kuma.port}
        '';
      };

      # --- FORGEJO (Protected from direct public access) ---
      "http://${myConstants.services.forgejo.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.forgejo.port}
        '';
      };

      # --- IMMICH (Public direct entrypoint - Auto HTTPS on 443) ---
      "${myConstants.services.immich.subdomain}.${domain}" = {
        extraConfig = ''
          log
          reverse_proxy 172.17.0.1:${toString myConstants.services.immich.port}
        '';
      };

      # --- NEXTCLOUD (Protected from direct public access) ---
      "http://${myConstants.services.nextcloud.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.nextcloud.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto https
          }
          
          # Crucial for Nextcloud desktop client discovery
          redir /.well-known/carddav /remote.php/dav 301
          redir /.well-known/caldav /remote.php/dav 301
          redir /.well-known/webfinger /index.php/.well-known/webfinger 301
          redir /.well-known/nodeinfo /index.php/.well-known/nodeinfo 301
        '';
      };

      # --- WANDERER WEB (Protected from direct public access) ---
      "http://${myConstants.services.wanderer.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.wanderer.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto https
          }
        '';
      };

      # --- WANDERER DB (Protected from direct public access) ---
      "http://${myConstants.services.wanderer-db.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          reverse_proxy 172.17.0.1:${toString myConstants.services.wanderer-db.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto https
          }
        '';
      };

      # --- SCANOPY (Protected from direct public access) ---
      "http://${myConstants.services.scanopy.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.scanopy.port}
        '';
      };

      # --- LLDAP (Protected from direct public access) ---
      "http://${myConstants.services.lldap.subdomain}.${domain}" = {
        extraConfig = ''
          ${privateOnly}
          ${authentikMiddleware}
          reverse_proxy 172.17.0.1:${toString myConstants.services.lldap.html-port}
        '';
      };

      # --- NETDATA (Protected from direct public access) ---
      "http://${myConstants.services.netdata.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${privateOnly}
          ${authentikMiddleware}
          
          # Netdata needs specific headers to know it is behind a proxy
          reverse_proxy 172.17.0.1:${toString myConstants.services.netdata.port} {
             header_up Host {host} 
             header_up X-Forwarded-Host {host}
             header_up X-Forwarded-For {remote}
             header_up X-Forwarded-Proto https
             flush_interval -1 
          }
        '';
      };
    };
  };
}