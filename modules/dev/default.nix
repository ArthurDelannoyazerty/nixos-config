{ pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    #  Essentials
    git
    # gcc
    # gnumake
    gh      # Github

    # Python
    python3 
    uv
    lazydocker

    # Java
    # jdk21 jdk17 jdk11 jdk8

    # IA
    opencode
    
  ];

  
  # Enable the Docker virtualisation service
  virtualisation.docker.enable = true;
  
  # Add your user to the 'docker' group to allow running docker commands
  # without needing to use `sudo`.
  users.groups.docker.members = [ "arthur" ];
}