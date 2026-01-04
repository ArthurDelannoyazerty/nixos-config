# /modules/constants.nix
{
  domain = "arthur-lab.duckdns.org";
  
  # A helper function to make 127.0.0.1 binding lazy/easy
  # Usage: bind 8501 -> "127.0.0.1:8501:8501"
  bind = port: "127.0.0.1:${toString port}:${toString port}";

  # THE REGISTRY
  services = {
    vikunja = {
      port = 3456;
      version = "1.0.0-rc3";
      subdomain = "vikunja";
    };
    finance = {
      port = 8501;
      subdomain = "finance";
    };
    homepage = {
      port = 3000;
      version = "v1.8.0";
      subdomain = "homepage"; # Optional: if you want homepage exposed
    };
    glances = {
      port = 61208;
      version = "4.4.1-full";
      subdomain = "glances"; # Optional: usually internal only
    };
    lldap = {
      port = 17170;
      subdomain = "users";
    };
    netdata = {
      port = 19999;
      subdomain = "netdata";
    };
    power-monitor = {
      port = 9100;
      # No subdomain here because not puclicly exposed
    };
  };
}