{ ... }:
{
  networking.firewall.allowedTCPPorts = [ 19999 ];
  virtualisation.oci-containers.containers.netdata = {
    image = "netdata/netdata:latest";
    ports = [ "19999:19999" ];
    extraOptions = [ "--cap-add=SYS_PTRACE" "--security-opt=apparmor=unconfined" ];
    volumes = [
      "/proc:/host/proc:ro"
      "/sys:/host/sys:ro"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
  };
}