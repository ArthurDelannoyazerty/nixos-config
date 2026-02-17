{ config, pkgs, myConstants, ... }:

let
  authentikMiddleware = ''
    # A. Handle Authentik Outpost (Bypass Auth)
    handle /outpost.goauthentik.io/* {
      reverse_proxy 127.0.0.1:${toString myConstants.services.authentik.port}
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

      # --- AUTHENTIK ITSELF ---
      "http://${myConstants.services.authentik.subdomain}.${domain}" = {
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

      # --- HOMEPAGE ---
      "http://${myConstants.services.homepage.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${authentikMiddleware} # Inject the auth logic
          reverse_proxy 127.0.0.1:${toString myConstants.services.homepage.port}
        '';
      };

      # --- FINANCE ---
      "http://${myConstants.services.finance.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${authentikMiddleware}
          reverse_proxy 127.0.0.1:${toString myConstants.services.finance.port}
        '';
      };

      # --- VIKUNJA ---
      "http://${myConstants.services.vikunja.subdomain}.${domain}" = {
        extraConfig = ''
          log
          reverse_proxy 127.0.0.1:3456 {
            header_up Host {host}
            header_up X-Real-IP {remote}
            header_up X-Forwarded-For {remote}
            header_up X-Forwarded-Proto https
          }        '';
      };

      # --- GLANCES ---
      "http://${myConstants.services.glances.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${authentikMiddleware}
          reverse_proxy 127.0.0.1:${toString myConstants.services.glances.port}
        '';
      };

      # --- LLDAP ---
      "http://${myConstants.services.lldap.subdomain}.${domain}" = {
        extraConfig = ''
          ${authentikMiddleware}
          reverse_proxy 127.0.0.1:${toString myConstants.services.lldap.html-port}
        '';
      };

      # --- NETDATA (Special Headers) ---
      "http://${myConstants.services.netdata.subdomain}.${domain}" = {
        extraConfig = ''
          log
          ${authentikMiddleware}
          
          # Netdata needs specific headers to know it is behind a proxy
          reverse_proxy 127.0.0.1:${toString myConstants.services.netdata.port} {
             header_up X-Forwarded-Host {host}
             header_up X-Forwarded-For {remote}
             header_up X-Forwarded-Proto https
          }
        '';
      };
    };
  };
}