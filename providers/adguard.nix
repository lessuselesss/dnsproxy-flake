{ pkgs, dnsproxy }:

let
  # Basic provider information
  name = "adguard";
  listenAddr = "127.140.14.14";  # Mnemonic IP for provider info (based on 94.140.14.14)
  listenPort = 5355;  # Use non-privileged port
  description = "DNS Proxy for AdGuard";
  
  # Default upstreams
  upstreams = [
    "94.140.14.14"
    "94.140.15.15"
    "2001:db8::1"  # Example IPv6 address
    "2001:db8::2"  # Example IPv6 address
  ];
  
  # Import the library functions
  lib = import ../lib.nix { inherit pkgs dnsproxy name listenAddr upstreams; };
  
  # Override only what's necessary from the defaults
  config = lib.mergeWithDefaults lib.defaultConfig {
    # Basic configuration
    port = listenPort;
    
    # Plain DNS configuration
    upstream = upstreams;
    
    # IPv6 configuration
    ipv6 = {
      enabled = true;
      listenAddr = "::1";
    };
  };

  # Create the scripts
  script = lib.createScript config;

in
{
  app = {
    "${name}" = {
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