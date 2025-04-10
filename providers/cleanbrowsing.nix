{ pkgs, dnsproxy }:

let
  # Basic provider information
  name = "cleanbrowsing";
  listenAddr = "127.228.168.9";  # Mnemonic IP for provider info (based on 185.228.168.9)
  listenPort = 5354;  # Use non-privileged port
  description = "DNS Proxy for CleanBrowsing";
  
  # Default upstreams
  upstreams = [
    "185.228.168.9"
    "185.228.169.9"
    "2001:1608:10:25::1c04:b12f"  # DNS.WATCH IPv6
    "2001:1608:10:25::9249:d69b"  # DNS.WATCH IPv6
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