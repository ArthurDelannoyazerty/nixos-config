{ config, pkgs, ... }:

let
  domain = "arthur-lab.duckdns.org"; # Your Domain
  
  # LLDAP Settings
  ldapBaseDN = "dc=arthur-lab,dc=duckdns,dc=org";
  ldapAdmin = "admin";
in
{
  # ==========================================================
  # 1. LLDAP - User Management Database (The GUI)
  # ==========================================================
  
  services.lldap = {
    enable = true;
    settings = {
      ldap_base_dn = ldapBaseDN;
      ldap_user_dn = "admin";
      # The email domain for users (e.g. user@arthur-homelab.duckdns.org)
      ldap_user_email = domain; 
      ldap_port = 3890;  # Internal LDAP port
      http_port = 17170; # Internal Web UI port
      http_url = "https://users.${domain}";
    };
    environment = {
      # Points to the files we created manually
      LLDAP_JWT_SECRET_FILE = "/var/lib/lldap/secrets/jwt_secret";
      LLDAP_LDAP_USER_PASS_FILE = "/var/lib/lldap/secrets/admin_password";
    };
  };

  # Ensure secret directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/lldap/secrets 0700 lldap lldap -"
  ];

  # ==========================================================
  # 2. AUTHELIA - The Bouncer (Now using LLDAP)
  # ==========================================================
  
  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = "/var/lib/authelia/secrets/jwt_secret";
      storageEncryptionKeyFile = "/var/lib/authelia/secrets/storage_key";
      sessionSecretFile = "/var/lib/authelia/secrets/session_secret";
      # Authelia needs the LLDAP admin password to read the database
      # We reuse the same file we created for LLDAP
      "ldap_password" = "/var/lib/lldap/secrets/admin_password"; 
    };

    settings = {
      theme = "dark";
      default_2fa_method = "totp";

      authentication_backend = {
        ldap = {
          url = "ldap://127.0.0.1:3890";
          implementation = "custom";
          base_dn = ldapBaseDN;
          username_attribute = "uid";
          additional_users_dn = "ou=people";
          additional_groups_dn = "ou=groups";
          # The user Authelia logs in as to check passwords
          user = "uid=admin,ou=people,${ldapBaseDN}"; 
        };
        # Password reset is now handled by LLDAP, so we disable it in Authelia
        password_reset.disable = true; 
      };
      
      session = {
        domain = domain;
        expiration = "12h"; 
      };

      storage.local.path = "/var/lib/authelia/db.sqlite3";

      access_control = {
        default_policy = "deny";
        rules = [
          { domain = "auth.${domain}"; policy = "bypass"; }
          # Allow all authenticated users to access services
          { domain = "*.${domain}"; policy = "one_factor"; }
        ];
      };
    };
  };

  # ==========================================================
  # 3. CADDY - Reverse Proxy
  # ==========================================================
  
  # DDNS Client
  services.ddclient = {
    enable = true;
    protocol = "duckdns";
    passwordFile = "/var/lib/secrets/duckdns_token";
    domains = [ domain ];
    interval = "5min";
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      # Authelia Portal
      "auth.${domain}".extraConfig = ''
        reverse_proxy http://127.0.0.1:9091
      '';

      # LLDAP User Management GUI (Where you create users)
      "users.${domain}".extraConfig = ''
        # We PROTECT this interface so random people can't try to login as admin
        forward_auth http://127.0.0.1:9091 {
            uri /api/verify?rd=https://auth.${domain}
            copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
        reverse_proxy http://127.0.0.1:17170
      '';

      # Your Apps
      "vikunja.${domain}".extraConfig = ''
        forward_auth http://127.0.0.1:9091 {
            uri /api/verify?rd=https://auth.${domain}
            copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
        reverse_proxy http://127.0.0.1:3456
      '';
      
      "finance.${domain}".extraConfig = ''
        forward_auth http://127.0.0.1:9091 {
            uri /api/verify?rd=https://auth.${domain}
            copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
        reverse_proxy http://127.0.0.1:8501
      '';
    };
  };
  
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}