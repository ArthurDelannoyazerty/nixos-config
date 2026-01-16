# /modules/services/headscale.nix
{ config, pkgs, myConstants, ... }:
let
  publicUrl = "https://${myConstants.services.headscale.subdomain}.${myConstants.publicDomain}";
in
{
  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = myConstants.services.headscale.port;
    settings = {
      server_url = publicUrl;
      dns = {
        base_domain = myConstants.domain;
        magic_dns = true;
        # Dns to redirect non local IP
        nameservers.global = [
          "1.1.1.1" # Cloudflare
          "8.8.8.8" # Google
        ];
        # Usually required to be true when using MagicDNS
        override_local_dns = true;
      };
      # oidc = {
      #   issuer = "https://${myConstants.services.authentik.subdomain}.${myConstants.publicDomain}/application/o/headscale/";
      #   client_id = "some-id-from-authentik";
      #   client_secret = "some-secret";
      # };
    };
  };

  environment.systemPackages = [ pkgs.headscale ];
}