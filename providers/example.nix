{ pkgs, lib, dnsproxy, ... }:

let
  # Import the library functions
  dnsproxy-lib = import ../lib.nix {
    inherit pkgs dnsproxy;
    name = "example";
    listenAddr = "127.0.0.1";
    upstreams = [
      "tls://1.1.1.1"
      "tls://1.0.0.1"
    ];
  };

  # Configuration with only non-default values
  config = {
    # Cache configuration
    cache = true;
    cacheSize = 8192;
    
    # Performance tuning
    timeout = "5s";
    
    # Security features
    refuseAny = true;
  };

  # Create the script
  script = dnsproxy-lib.createScript config;

  # Create the systemd service
  service = dnsproxy-lib.createSystemdService config;

in
{
  # Make the script available in the system
  environment.systemPackages = [ script ];

  # Enable the systemd service
  systemd.services."dnsproxy-${dnsproxy-lib.name}" = service;
} 