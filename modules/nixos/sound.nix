# /modules/nixos/sound.nix
{ pkgs, ... }:

{
  # Enable RealtimeKit for low-latency audio scheduling
  security.rtkit.enable = true;

  # Enable PipeWire for audio management
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # Enables PulseAudio compatibility
    jack.enable = true;  # For music production tools
  };
}