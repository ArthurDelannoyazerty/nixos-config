# /modules/services/lldap/lldap.nix
{ config, pkgs, myConstants, ... }:

{
  services.lldap = {
    enable = true;
    settings = {
      ldap_port = myConstants.services.lldap.port;
      http_port = 17171; # Web UI for managing users
      http_url = "http://lldap.local";
      ldap_base_dn = "dc=home,dc=arpa";
      
      # You need to set a secret for this in a real setup, 
      # but for now we set a declarative password for the admin.
      # CHANGE THIS after first boot via the UI or secret management!
      jwt_secret = "REPLACE_WITH_RANDOM_STRING_SECRET";
      ldap_user_pass = "adminpassword"; 
    };
  };

  # Open the firewall ONLY for the VPN interface (setup in Step 4)
  # or keep it closed and let the Reverse Proxy talk to it via localhost.
}