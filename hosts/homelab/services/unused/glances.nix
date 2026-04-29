{ pkgs, myConstants, ... }:

let
  cfg = myConstants.services.glances; 
in
{
  virtualisation.oci-containers.containers.glances = {
    image = "nicolargo/glances:${cfg.version}";
    # Run in Web Server mode (-w)
    cmd = [ 
      "glances" 
      "-w"
      "-t" "5"
      "--disable-plugin" "all" 
      "--enable-plugin" "cpu,mem,fs,processlist,uptime,sensors,wifi,containers" 
    ];
    ports = [ (myConstants.bind cfg.port) ];
    # Essential for monitoring the actual Host
    extraOptions = [ "--pid=host" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:ro"
      "/proc:/proc" # Read access to system processes
      "/sys:/sys"   # Read access to system info
    ];
  };
}