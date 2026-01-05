# /modules/services/headscale.nix
{ config, pkgs, myConstants ... }:
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
      dns_config.base_domain = myConstants.domain;
      # For reverse proxying
      ip_prefixes = [
        "fd7a:115c:a1e0::/48"
        "100.64.0.0/10"
      ];
    };
  };

  environment.systemPackages = [ pkgs.headscale ];
}