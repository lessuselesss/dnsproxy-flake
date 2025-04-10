{ pkgs, dnsproxy }:

let
  # Basic provider information
  name = "quad9";
  listenAddr = "127.9.9.99";
  listenPort = 53;
  description = "DNS Proxy for Quad9";
  
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
        "dns://9.9.9.9"
        "dns://149.112.112.112"
      ];
    };
    
    # DoT configuration (commented out by default)
    dot = {
      enabled = false;
      upstream = "tls://dns.quad9.net";
    };
    
    # IPv6 DoT configuration (commented out by default)
    ipv6 = {
      enabled = true;
      listenAddr = "::1";
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