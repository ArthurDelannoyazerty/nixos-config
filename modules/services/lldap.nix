# /modules/services/lldap/lldap.nix
{ config, pkgs, myConstants, ... }:

{
  services.lldap = {
    enable = true;
    # Silence the fact that modifying password in the UI desynchronize it from the one in the file that stays
    silenceForceUserPassResetWarning = true;

    settings = {
      ldap_port = myConstants.services.lldap.port;
      http_port = myConstants.services.lldap.html-port; # Web UI for managing users
      http_url = "http://${myConstants.services.lldap.subdomain}.${myConstants.publicDomain}";
      ldap_base_dn = "dc=arthur-lab,dc=com";   

      jwt_secret_file = "/var/lib/lldap/secrets/jwt_secret";
      ldap_user_pass_file = "/var/lib/lldap/secrets/admin_password";

      # Allows Authentik to talk to LLDAP      
      database_config.file = "/var/lib/lldap/lldap.db";
    };
  };

  # Open the LDAP port for internal container communication
  # networking.firewall.allowedTCPPorts = [  ];
}