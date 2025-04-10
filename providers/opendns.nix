{ pkgs, dnsproxy }:

let
  # Basic provider information
  name = "opendns";
  listenAddr = "127.208.67.222";
  listenPort = 53;
  description = "DNS Proxy for OpenDNS";
  
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
        "208.67.222.222"
        "208.67.220.220"
        "dns://[2620:0:ccc::2]"  # OpenDNS IPv6
        "dns://[2620:0:ccd::2]"  # OpenDNS IPv6
      ];
    };
    
    # IPv6 configuration
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