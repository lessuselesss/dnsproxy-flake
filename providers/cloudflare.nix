{ pkgs, dnsproxy }:

let
  # Basic provider information
  name = "cloudflare";
  listenAddr = "127.0.0.1"; # Standard localhost address
  listenPort = 5353; # Use non-privileged port
  description = "DNS Proxy for Cloudflare";
  
  # Default upstreams
  upstreams = [
    # IPv4 addresses
    "1.1.1.1"
    "1.0.0.1"
    # IPv6 addresses
    "2606:4700:4700::1111"
    "2606:4700:4700::1001"
  ];
  
  # Import the library functions
  lib = import ../lib.nix { inherit pkgs dnsproxy name listenAddr upstreams; };
  
  # Override only what's necessary from the defaults
  config = lib.mergeWithDefaults lib.defaultConfig {
    # Basic configuration
    port = listenPort;
    
    # Plain DNS configuration
    upstream = upstreams;
    
    # DoT configuration
    dot = {
      enabled = true;
      upstream = "tls://cloudflare-dns.com";
      # Family DNS (Malware blocking + Adult content)
      # upstream = "tls://family.cloudflare-dns.com";
      # Security DNS (Malware blocking only)
      # upstream = "tls://security.cloudflare-dns.com";
    };
    
    # DoH configuration
    doh = {
      enabled = true;
      upstream = "https://cloudflare-dns.com/dns-query";
      # Family DNS (Malware blocking + Adult content)
      # upstream = "https://family.cloudflare-dns.com/dns-query";
      # Security DNS (Malware blocking only)
      # upstream = "https://security.cloudflare-dns.com/dns-query";
    };
    
    # DoQ configuration
    doq = {
      enabled = true;
      upstream = "quic://cloudflare-dns.com";
      # Family DNS (Malware blocking + Adult content)
      # upstream = "quic://family.cloudflare-dns.com";
      # Security DNS (Malware blocking only)
      # upstream = "quic://security.cloudflare-dns.com";
    };
    
    # DNSCrypt configuration
    dnscrypt = {
      enabled = true;
      stamp = "sdns://AgcAAAAAAAAABzEuMC4wLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5";
      # Family DNS (Malware blocking + Adult content)
      # stamp = "sdns://AgcAAAAAAAAABzEuMC4wLjMAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5";
      # Security DNS (Malware blocking only)
      # stamp = "sdns://AgcAAAAAAAAABzEuMC4wLjIAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5";
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
    "${name}" = {
      type = "app";
      program = "${script}";
    };
  };
  
  # Provider IP address information
  providerInfo = {
    name = name;
    description = description;
    listenAddr = listenAddr;
    listenPort = listenPort;
    ipv6 = config.ipv6;
    upstreamAddresses = {
      plain = config.plainDns.upstreams;
      dot = if config.dot.enabled then [config.dot.upstream] else [];
      doh = if config.doh.enabled then [config.doh.upstream] else [];
      doq = if config.doq.enabled then [config.doq.upstream] else [];
      dnscrypt = if config.dnscrypt.enabled then [config.dnscrypt.stamp] else [];
    };
  };
} 