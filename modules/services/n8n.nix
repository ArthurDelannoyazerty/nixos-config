{ config, pkgs, myConstants, ... }:


{
  systemd.tmpfiles.rules =[
    "d /var/lib/n8n 0750 1000 1000 -"
  ];

  virtualisation.oci-containers.containers.${myConstants.services.n8n.containerName} = {
    image = "docker.n8n.io/n8nio/n8n:${myConstants.services.n8n.version}";
    ports =[ "0.0.0.0:${toString myConstants.services.n8n.port}:5678" ];
    volumes =[
      "/var/lib/n8n:/home/node/.n8n"
    ];
    environment = {
      # Tell n8n how it is accessed from the outside so webhooks generate correct URLs
      WEBHOOK_URL = "https://${myConstants.services.n8n.subdomain}.${myConstants.publicDomain}/";
      GENERIC_TIMEZONE = "Europe/Paris";

      #Disable the user management as we will use authentik for authentication      
      N8N_USER_MANAGEMENT_DISABLED = "true"; 
    };
  };
}