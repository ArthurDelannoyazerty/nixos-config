{ config, pkgs, myConstants, ... }:

{
  # Virtual user for secrets owning
  users.groups.lldap = { };
  users.users.lldap = {
    isSystemUser = true;
    group = "lldap";
  };

  services.lldap = {
    enable = true;
    # Silence the fact that modifying password in the UI desynchronize it from the one in the file that stays
    silenceForceUserPassResetWarning = true;

    settings = {
      ldap_port = myConstants.services.lldap.port;
      http_port = myConstants.services.lldap.html-port; # Web UI for managing users
      http_url = "http://${myConstants.services.lldap.subdomain}.${myConstants.publicDomain}";
      ldap_base_dn = "dc=arthur-lab,dc=com";   

      jwt_secret_file =      "${myConstants.paths.servicesSSD}/lldap/jwt_secret_file";
      ldap_user_pass_file =  "${myConstants.paths.servicesSSD}/lldap/secrets/admin_password";
      database_config.file = "${myConstants.paths.servicesSSD}/lldap/users.db";
    };
  };

  # Open the LDAP port for internal container communication
  # networking.firewall.allowedTCPPorts = [  ];
}