{ pkgs, dnsproxy }:

let
  # Basic provider information
  name = "example";
  listenAddr = "127.0.0.1";
  listenPort = 53;
  description = "Example DNS Provider Configuration";
  
  # Import the library functions
  lib = import ../lib.nix { inherit pkgs dnsproxy name listenAddr; };
  
  # Override only what's necessary from the defaults
  config = lib.mergeWithDefaults lib.defaultConfig {
    # Basic configuration
    port = listenPort;
    
    # Plain DNS configuration
    plainDns = {
      enabled = true;
      upstreams = [
        "9.9.9.9"
        "149.112.112.112"
      ];
    };
  };

  # Create the script
  script = lib.createScript config;

in
{
  app = {
    "dnsproxy-${name}" = {
      type = "app";
      program = "${script}";
    };
  };

  systemdService = {
    "dnsproxy-${name}" = lib.createSystemdService config;
  };
  
  # Provider IP address information
  providerInfo = lib.createProviderInfo config;
} 