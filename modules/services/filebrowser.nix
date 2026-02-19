{ config, pkgs, myConstants, ... }: {
  services.filebrowser = {
    enable = true;
    # The root directory to manage
    root = "/"; 
    port = ${myConstants.services.filebrowser.port};
  };
}