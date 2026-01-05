# /modules/services/cloudflared/cloudflared.nix
{ config, pkgs, myConstants, ... }:

let
  # The tunnel ID and credentials file location
  # You get these by running `cloudflared tunnel create my-tunnel` locally
  tunnelID = "YOUR-TUNNEL-UUID-HERE"; 
  credsFile = "/var/lib/cloudflared/cert.json"; # You must copy the credentials here manually once
in
{
  services.cloudflared = {
    enable = true;
    tunnels = {
      "${tunnelID}" = {
        credentialsFile = credsFile;
        default_ingress = {
          service = "http_status:404";
        };
        ingress = {
          # 1. Public Headscale Endpoint (Traffic goes to Caddy or direct)
          "${myConstants.services.headscale.subdomain}.${myConstants.publicDomain}" = {
            service = "http://localhost:${toString myConstants.services.headscale.port}";
          };
          
          # 2. Public Headscale UI (So you can approve users from anywhere)
          "${myConstants.services.headscale-ui.subdomain}.${myConstants.publicDomain}" = {
             service = "http://localhost:${toString myConstants.services.headscale-ui.port}";
          };
        };
      };
    };
  };
}