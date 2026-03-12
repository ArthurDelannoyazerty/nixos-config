{ config, pkgs, myConstants, ... }:

let
  port = myConstants.services.n8n.port;
  domain = myConstants.publicDomain;
  subdomain = myConstants.services.n8n.subdomain;
in
{
  systemd.tmpfiles.rules =[
    "d /var/lib/n8n 0750 1000 1000 -"
  ];

  virtualisation.oci-containers.containers."n8n" = {
    image = "docker.n8n.io/n8nio/n8n:${myConstants.services.n8n.version}";
    ports =[ "127.0.0.1:${toString port}:5678" ];
    volumes =[
      "/var/lib/n8n:/home/node/.n8n"
    ];
    environment = {
      # Tell n8n how it is accessed from the outside so webhooks generate correct URLs
      WEBHOOK_URL = "https://${subdomain}.${domain}/";
      GENERIC_TIMEZONE = "Europe/Paris";

      #DIsable the user management as we will use authentik for authentication      
      N8N_USER_MANAGEMENT_DISABLED = "true"; 
    };
  };
}