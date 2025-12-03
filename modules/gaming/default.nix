{ pkgs, ... }:

{
  # =========================================================================
  # == GRAPHICS DRIVERS & 32-BIT SUPPORT
  #    Essential for running most games via Steam/Proton.
  # =========================================================================

  # Enable 32-bit application support
  hardware.graphics = {
      enable = true;
      enable32Bit = true;
  };

  # --- Choose your GPU driver ---
  # Uncomment the section corresponding to your graphics card.

  # For NVIDIA:
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia.modesetting.enable = true;

  # For AMD / Intel (Mesa drivers are often enabled by default, but this is explicit)
  # hardware.opengl.extraPackages = with pkgs; [ amdvlk ]; # Optional: AMD's official Vulkan driver


  # =========================================================================
  # == GAMING SOFTWARE & SERVICES
  # =========================================================================

  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # For hosting game servers
  };

  # Enable GameMode for performance optimizations
  programs.gamemode.enable = true;

  # Add common gaming utilities to the system path
  environment.systemPackages = with pkgs; [
    lutris      # Unified gaming launcher
    mangohud    # Performance overlay
    gamescope   # Micro-compositor for games
  ];
}