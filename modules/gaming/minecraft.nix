{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs;[
    # Override Prism Launcher to inject your desired Java versions directly
    (prismlauncher.override {
      jdks =[ 
        jdk8 
        jdk17 
        jdk21 
        jdk25 
      ];
    })
  ];
}