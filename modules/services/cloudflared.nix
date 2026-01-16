# /modules/services/cloudflared/cloudflared.nix
{ config, pkgs, myConstants, ... }:

let
  tunnelID = "f9408fae-a6b0-420a-a348-cc974402228f"; 
  credsFile = "/var/lib/cloudflared/cert.json"; # You must copy the credentials here manually once
in
{
  services.cloudflared = {
    enable = true;
    tunnels = {
      "${tunnelID}" = {
        credentialsFile = credsFile;
        default = "http://localhost:80"; 
        ingress = {
          # Route the Auth portal directly
          "${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}" = "http://127.0.0.1:${toString myConstants.services.authentik.port}";
          
          # Headscale needs to be public for the Highway path
          "${myConstants.services.headscale.subdomain}.${myConstants.publicDomain}" = "http://127.0.0.1:${toString myConstants.services.headscale.port}";
          };
      };
    };
  };
}