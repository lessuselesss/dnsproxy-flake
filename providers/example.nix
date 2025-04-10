{ pkgs, dnsproxy }:

let
  # Import the library functions
  lib = import ../lib.nix { inherit pkgs dnsproxy; };
  
  # Basic provider information
  name = "example";
  listenAddr = "127.0.0.1";
  listenPort = 53;
  description = "Example DNS Provider Configuration";
  
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