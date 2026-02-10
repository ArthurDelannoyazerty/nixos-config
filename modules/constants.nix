# /modules/constants.nix
{
  # Internal domain for services
  domain = "home.arpa";

  # Public domain
  publicDomain = "arthur-lab.com"; 
  
  # Usage: bind 8501 -> "0.0.0.0:8501:8501"
  bind = port: "0.0.0.0:${toString port}:${toString port}";

  # THE REGISTRY
  services = {
    vikunja = {
      port = 3456;
      subdomain = "vikunja";
      version = "1.0.0-rc3";
    };
    finance = {
      port = 8501;
      subdomain = "finance";
    };
    homepage = {
      port = 3000;
      subdomain = "homepage";
      version = "v1.8.0";
    };
    glances = {
      port = 61208;
      subdomain = "glances";
      version = "4.4.1-full";
    };
    lldap = {
      port = 3890;
      html-port = 17171;
      subdomain = "lldap";
    };
    netdata = {
      port = 19999;
      subdomain = "netdata";
    };
    power-monitor = {
      port = 9100;
    };
    headscale = {
      port = 8080;
      subdomain = "headscale";
    };
    headscale-ui = {
      port = 9443;
      subdomain = "headscale-ui";
      version = "latest";
    };
    authentik = {
      port = 9000;
      subdomain = "authentik";
    };
  };
}