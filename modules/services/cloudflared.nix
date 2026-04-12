# /modules/services/cloudflared/cloudflared.nix
{ config, pkgs, myConstants, ... }:

let
  tunnelID = "87d1700f-f74e-4f2a-89cf-8c217a750106"; 
  credsFile = "/var/lib/cloudflared/cert.json"; # You must copy the credentials here manually once
in
{
  services.cloudflared = {
    enable = true;
    tunnels = {
      "${tunnelID}" = {
        credentialsFile = credsFile;
        default = "http://127.0.0.1:80"; 
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