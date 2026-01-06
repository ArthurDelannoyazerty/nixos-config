# /modules/services/lldap/lldap.nix
{ config, pkgs, myConstants, ... }:

{
  services.lldap = {
    enable = true;
    settings = {
      ldap_port = myConstants.services.lldap.port;
      http_port = myConstants.services.lldap.html-port; # Web UI for managing users
      http_url = "http://${myConstants.services.lldap.subdomain}.${myConstants.publicDomain}";
      ldap_base_dn = "dc=arthur-lab,dc=com";      
      jwt_secret_file = "/var/lib/lldap/jwt_secret";
      # Allows Authentik to talk to LLDAP      
      database_config.file = "/var/lib/lldap/lldap.db";
    };
  };

  # Open the LDAP port for internal container communication
  # networking.firewall.allowedTCPPorts = [  ];
}