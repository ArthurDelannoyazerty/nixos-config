{ pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 61208 ];

  virtualisation.oci-containers.containers.glances = {
    image = "nicolargo/glances:latest-full";
    # Run in Web Server mode (-w)
    cmd = [ 
      "glances" 
      "-w"
      "-t" "5"
      "--disable-plugin" "all" 
      "--enable-plugin" "cpu,mem,fs,processlist,uptime,sensors,wifi,containers" 
    ];
    ports = [ "61208:61208" ];
    # Essential for monitoring the actual Host
    extraOptions = [ "--pid=host" ];
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:ro"
      "/proc:/proc" # Read access to system processes
      "/sys:/sys"   # Read access to system info
    ];
  };
}