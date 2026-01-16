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
        forward_auth 127.0.0.1:${toString myConstants.services.authentik.port} {
          uri /outpost.goauthentik.io/auth/caddy
          copy_headers X-Forwarded-Method X-Forwarded-Uri X-Forwarded-For
          # Trick Authentik into thinking the connection is HTTPS
          header_up X-Forwarded-Proto https
          # Tell Authentik which domain is being requested 
          header_up Host {host}
        }
      }
    '';

    virtualHosts = {
      
      # 3. ROOT DOMAIN REDIRECT
      # http://arthur-lab.com -> https://homepage.arthur-lab.com
      "http://${myConstants.publicDomain}" = {
        extraConfig = ''
          redir https://${myConstants.services.homepage.subdomain}.${myConstants.publicDomain} permanent
        '';
      };

      # 4. HOMEPAGE
      "http://${myConstants.services.homepage.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          import snippet_authentik
          reverse_proxy 127.0.0.1:${toString myConstants.services.homepage.port}
        '';
      };

      # 5. FINANCE
      "http://${myConstants.services.finance.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          import snippet_authentik
          reverse_proxy 127.0.0.1:${toString myConstants.services.finance.port} {
            header_up Remote-User {http.auth.user.id}
            header_up Remote-Groups {http.auth.user.groups}
          }
        '';
      };

      # 6. GLANCES
      "http://${myConstants.services.glances.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
          import snippet_authentik
          reverse_proxy 127.0.0.1:${toString myConstants.services.glances.port}
        '';
      };
      
      # 7. LLDAP
      "http://${myConstants.services.lldap.subdomain}.${myConstants.publicDomain}" = {
        extraConfig = ''
             import snippet_authentik
             reverse_proxy 127.0.0.1:${toString myConstants.services.lldap.html-port}
        '';
      };
    };
  };
}