{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs;[
    prismlauncher  # Replace with atlauncher, modrinth-app, or gdlauncher
    
    # Optional: It is highly recommended to install Java versions globally
    # so your launcher can automatically find them for different MC versions.
    jdk8           # For Minecraft 1.16.5 and older
    jdk17          # For Minecraft 1.17 to 1.20.4
    jdk21          # For Minecraft 1.20.5 and newer
  ];
}