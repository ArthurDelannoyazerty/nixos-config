# /hosts/homelab/services/random/crafty-controller.nix

{ config, pkgs, myConstants, ... }:

{
  virtualisation.oci-containers.containers.${myConstants.services.crafty-controller.containerName} = {
    image = "registry.gitlab.com/crafty-controller/crafty-4:${myConstants.services.crafty-controller.version}";
    
    ports =[
      # Web UI is bound to Docker network, accessed safely via Caddy reverse proxy
      (myConstants.bind myConstants.services.crafty-controller.port) 
      
      # Game ports bound to ALL local interfaces (0.0.0.0). 
      # Since the router is not port-forwarding, the public internet cannot reach this.
      # Players on your LAN or Tailscale CAN reach this.
      "25500-25600:25500-25600/tcp" 
      "25500-25600:25500-25600/udp" 
      "19132:19132/udp"             
    ];

    environment = {
      TZ = "Europe/Paris"; 
    };

    volumes =[
      # Fast SSD storage for running the servers & DB (improves chunk loading)
      "${myConstants.paths.servicesSSD}/crafty/servers:/crafty/servers"
      "${myConstants.paths.servicesSSD}/crafty/config:/crafty/app/config"
      
      # Bulk HDD storage for heavy static data like backups
      "${myConstants.paths.disk2TB}/crafty/backups:/crafty/backups"
      "${myConstants.paths.disk2TB}/crafty/logs:/crafty/logs"
      "${myConstants.paths.disk2TB}/crafty/import:/crafty/import"
    ];
  };
}