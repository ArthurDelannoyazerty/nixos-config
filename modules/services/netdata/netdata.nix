{myConstants, ... }:
{
  virtualisation.oci-containers.containers.netdata = {
    image = "netdata/netdata:latest";
    ports = [ (myConstants.bind myConstants.services.netdata.port) ];
    extraOptions = [ "--cap-add=SYS_PTRACE" "--security-opt=apparmor=unconfined" ];
    volumes = [
      "/proc:/host/proc:ro"
      "/sys:/host/sys:ro"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
  };
}