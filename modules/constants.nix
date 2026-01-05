# /modules/constants.nix
{
  # Internal domain for services
  domain = "home.arpa";

  # Public domain (for headscale for now)
  publicDomain = "arthur-lab.duckdns.org"; 
  
  # A helper function to make 127.0.0.1 binding lazy/easy
  # Usage: bind 8501 -> "127.0.0.1:8501:8501"
  bind = port: "127.0.0.1:${toString port}:${toString port}";

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
      port = 17171;
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
    }
    headscale-ui = {
      port = 9443;
      subdomain = "headscale-ui";
      version = "latest";
    }
  };
}