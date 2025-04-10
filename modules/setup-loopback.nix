{ pkgs }:

let
  # List of all mnemonic IP addresses used by the providers
  loopbackAddresses = [
    "127.1.1.11"    # Cloudflare Tor
    "127.8.8.88"    # Google
    "127.9.9.99"    # Quad9
    "127.94.14.14"  # AdGuard
    "127.208.67.222" # OpenDNS
    "127.64.6.64"   # Verisign
    "127.185.39.10" # DNS.WATCH
    "127.145.97.171" # CleanBrowsing
    "127.77.36.11"  # UncensoredDNS
    "127.45.45.45"  # NextDNS
  ];

  # Create a platform-specific setup script
  setupScript = pkgs.writeShellScript "setup-loopback-addresses" ''
    platform=$(uname)
    
    if [ "$platform" = "Darwin" ]; then
      # macOS setup
      for ip in ${builtins.concatStringsSep " " loopbackAddresses}; do
        sudo ifconfig lo0 alias $ip up
      done
      echo "Configured loopback aliases on macOS"
    elif [ "$platform" = "Linux" ]; then
      # Linux setup - normally not needed as Linux allows all 127.x.x.x
      # But we'll add them explicitly to be safe
      for ip in ${builtins.concatStringsSep " " loopbackAddresses}; do
        sudo ip addr add $ip/8 dev lo
      done
      echo "Configured loopback aliases on Linux"
    else
      echo "Unsupported platform: $platform"
      exit 1
    fi
    
    # Test if the addresses are properly configured
    for ip in ${builtins.concatStringsSep " " loopbackAddresses}; do
      ping -c 1 $ip > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        echo "✅ $ip is configured"
      else
        echo "❌ $ip is NOT properly configured"
      fi
    done
  '';
in {
  type = "app";
  program = "${setupScript}";
} 