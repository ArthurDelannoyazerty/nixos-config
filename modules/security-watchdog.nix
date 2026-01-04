# /modules/nixos/security-watchdog.nix
{ config, lib, myConstants, ... }:

let
  # Extract just the port numbers from our constants
  internalPorts = lib.mapAttrsToList (name: value: value.port) myConstants.services;
  
  # The currently open firewall ports
  openPorts = config.networking.firewall.allowedTCPPorts;

  # Check if any internal port is in the open ports list
  # Returns the first matching port or null
  exposedPort = lib.findFirst (p: builtins.elem p openPorts) null internalPorts;
in
{
  # If 'exposedPort' is NOT null, crash the build with a message
  assertions = [
    {
      assertion = (exposedPort == null);
      message = "CRITICAL SECURITY ERROR: You have opened port ${toString exposedPort} in the firewall, but it is defined as an internal service in constants.nix! Remove it from networking.firewall.allowedTCPPorts.";
    }
  ];
}