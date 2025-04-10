# Template for DNS provider modules
# Copy this file to create a new provider
# Replace placeholders marked with <PLACEHOLDER> with actual values

{ pkgs, dnsproxy }:

let
  # Import the library functions
  lib = import ../lib.nix { inherit pkgs dnsproxy; };
  
  # Basic provider information
  name = "template";
  listenAddr = "127.0.0.1";
  listenPort = 53;
  description = "DNS Proxy Template";
  
  # Override only what's necessary from the defaults
  config = lib.mergeWithDefaults lib.defaultConfig {
    # Basic configuration
    port = listenPort;
    
    # Plain DNS configuration
    plainDns = {
      enabled = true;
      upstreams = [
        # Add your upstream servers here
        "1.1.1.1"
        "1.0.0.1"
      ];
    };
    
    # DoT configuration
    dot = {
      enabled = true;
      upstream = "tls://cloudflare-dns.com";
    };
    
    # DoH configuration
    doh = {
      enabled = true;
      upstream = "https://cloudflare-dns.com/dns-query";
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
} 