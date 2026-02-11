{ config, pkgs, myConstants, ... }:

{
  services.caddy = {
    enable = true;
    
    # 1. Global settings (Trust Cloudflare IPs)
    globalConfig = ''
      servers {
        trusted_proxies static private_ranges
      }
    '';

    # 2. Define the Snippet here (Global Scope)
    # This guarantees it exists before any site tries to import it.
    extraConfig = ''
      (snippet_authentik) {
        # 1. Handle Authentik's internal paths (Bypass Auth Check)
        # This must be a 'handle' so it stops here and proxies directly.
        handle /outpost.goauthentik.io/* {
          reverse_proxy 127.0.0.1:9000{
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto https
          }
        }

        # 2. Check authentication for everything else
        # We use a matcher to exclude the outpost paths.
        @not_authentik {
          not path /outpost.goauthentik.io/*
        }

        # forward_auth is a directive: if it returns 2xx, Caddy continues 
        # to the rest of the virtual host (your app).
        forward_auth @not_authentik 127.0.0.1:9000 {
          uri /outpost.goauthentik.io/auth/caddy
          copy_headers X-Forwarded-Method X-Forwarded-Uri X-Forwarded-For X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Name X-Authentik-Uid
          header_up Host {host}
          header_up X-Real-IP {remote}
          header_up X-Forwarded-For {remote}
          header_up X-Forwarded-Proto https
        }

        # 3. If Authentik returns 401 (Unauthorized), redirect to login
        handle_errors {
          @401 expression {err.status_code} == 401
          handle @401 {
            redir https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/outpost.goauthentik.io/start?rd={request.uri}          }
        }
      }
    '';

    virtualHosts = {
      
      # ROOT DOMAIN REDIRECT
      # http://arthur-lab.com -> https://homepage.arthur-lab.com
      "http://${myConstants.publicDomain}" = {
        extraConfig = ''
          log
          redir https://${myConstants.services.homepage.subdomain}.${myConstants.publicDomain} permanent
        '';
      };

      "http://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          log
          reverse_proxy 127.0.0.1:${toString myConstants.services.authentik.port} {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto https
          }
        '';
      };

      # HOMEPAGE
      "http://${myConstants.services.homepage.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          log
          import snippet_authentik
          reverse_proxy 127.0.0.1:${toString myConstants.services.homepage.port}
        '';
      };

      # FINANCE
      "http://${myConstants.services.finance.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          log
          import snippet_authentik
          reverse_proxy 127.0.0.1:${toString myConstants.services.finance.port} {
            header_up Remote-User {http.auth.user.id}
            header_up Remote-Groups {http.auth.user.groups}
          }
        '';
      };

      # GLANCES
      "http://${myConstants.services.glances.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          log
          import snippet_authentik
          reverse_proxy 127.0.0.1:${toString myConstants.services.glances.port}
        '';
      };

      #VIKUNJA
      "http://${myConstants.services.vikunja.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          log
          import snippet_authentik ${toString myConstants.services.vikunja.port}
        '';
      };

      # NETDATA (custom config because picky apparently)
      "http://${myConstants.services.netdata.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          log
          
          # 1. Handle Authentik Outpost (Standard)
          handle /outpost.goauthentik.io/* {
            reverse_proxy 127.0.0.1:9000
          }

          # 2. Auth Check (Standard)
          forward_auth 127.0.0.1:9000 {
            uri /outpost.goauthentik.io/auth/caddy
            copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt
            header_up Host {host}
          }

          # 3. PROXY WITH SPECIAL NETDATA HEADERS
          reverse_proxy 127.0.0.1:${toString myConstants.services.netdata.port} {
             # These are crucial for Netdata to render charts behind a proxy
             header_up X-Forwarded-Host {host}
             header_up X-Forwarded-For {remote}
             header_up X-Forwarded-Proto https
          }

          # 4. Redirect on 401 (Standard)
          handle_errors {
            @401 expression {err.status_code} == 401
            handle @401 {
              redir https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/outpost.goauthentik.io/start?rd={request.uri}
            }
          }
        '';
      };
      
      # LLDAP
      "http://${myConstants.services.lldap.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
             import snippet_authentik
             reverse_proxy 127.0.0.1:${toString myConstants.services.lldap.html-port}
        '';
      };
    };
  };
}