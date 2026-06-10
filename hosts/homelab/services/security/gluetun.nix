{ config, pkgs, myConstants, ... }:

{
  # Pre-create the directory for Gluetun
  systemd.tmpfiles.rules = [
    "d ${myConstants.paths.servicesSSD}/gluetun 0755 1000 1000 -"
  ];

  virtualisation.oci-containers.containers."${myConstants.services.gluetun.containerName}" = {
    image = "ghcr.io/qdm12/gluetun:${myConstants.services.gluetun.version}";
    
    # CRITICAL: Gluetun needs network admin privileges and the tun device to establish the VPN
    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--device=/dev/net/tun:/dev/net/tun"
    ];

    ports = [ 
      # Expose the HTTP Control Server API (Not a Web Page)
      (myConstants.bind myConstants.services.gluetun.port)

      # ⚠️ IMPORTANT ROUTING NOTE ⚠️
      # If you route other containers (like qBittorrent/Prowlarr) through Gluetun,
      # you MUST expose their ports HERE, and delete the ports from their own config!
      # 
      # Example for qBittorrent (8095 = WebUI, 6881 = Torrent peers)
      # "0.0.0.0:8095:8095"
      # "0.0.0.0:6881:6881/tcp"
      # "0.0.0.0:6881:6881/udp"
    ];

    environment = {
      TZ = "Europe/Paris";
      
      # --- VPN PROVIDER SETTINGS ---
      # Example for a Custom WireGuard configuration.
      # You can change this to protonvpn, mullvad, nordvpn, etc.
      VPN_SERVICE_PROVIDER = "custom"; 
      VPN_TYPE = "wireguard";
      
      # (Example) WireGuard Variables
      # WIREGUARD_PRIVATE_KEY = "YOUR_PRIVATE_KEY";
      # WIREGUARD_ADDRESSES = "10.2.0.2/32";
      
      # (Example) OpenVPN Variables
      # OPENVPN_USER = "user";
      # OPENVPN_PASSWORD = "password";

      # Let local network traffic access the containers routed through Gluetun
      # Adjust to your home subnet (e.g., 192.168.1.0/24)
      FIREWALL_OUTBOUND_SUBNETS = "192.168.0.0/16,172.16.0.0/12"; 
    };

    volumes = [
      "${myConstants.paths.servicesSSD}/gluetun:/gluetun"
    ];
  };
}