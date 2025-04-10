{ pkgs, dnsproxy }:

let
  # Basic provider information
  name = "dns64-private";
  listenAddr = "127.0.0.64"; # Mnemonic IP for DNS64
  listenPort = 53;
  description = "DNS64 Proxy with Private Upstream";
  
  # IPv6 listen configuration
  ipv6 = {
    enabled = true;
    listenAddr = "::1"; # IPv6 localhost
    # Alternatively, you could use a unique IPv6 address on your network
    # listenAddr = "fd00::64"; # Example of ULA (Unique Local Address)
  };
  
  # Private DNS upstream configuration
  privateDns = {
    enabled = true;
    upstreams = [
      # IPv4 private DNS servers
      "192.168.1.53"  # Example of a private DNS server on local network
      "10.0.0.53"     # Example of a private DNS server on corporate network
      # IPv6 private DNS servers
      "fd00::53"      # Example of a private IPv6 DNS server (ULA)
      "2001:db8::53"  # Example of a private IPv6 DNS server (documentation prefix)
    ];
  };
  
  # DoT (DNS over TLS) configuration - disabled for private example
  dot = {
    enabled = false;
    upstream = "";
  };
  
  # DoH (DNS over HTTPS) configuration - disabled for private example
  doh = {
    enabled = false;
    upstream = "";
  };
  
  # DoQ (DNS over QUIC) configuration - disabled for private example
  doq = {
    enabled = false;
    upstream = "";
  };
  
  # DNSCrypt configuration - disabled for private example
  dnscrypt = {
    enabled = false;
    stamp = "";
  };
  
  # Default protocol to use (plain, dot, doh, doq, dnscrypt)
  defaultProtocol = "plain";
  
  # DNS64 configuration is enabled by default
  dns64 = {
    enabled = true;
    prefix = "64:ff9b::"; # Standard DNS64 prefix
  };
  
  # Bogus NX domain configuration
  bogusNX = {
    enabled = true;
    domains = [
      "example.invalid"
      "non-existent-domain.local"
      "bogus.example.test"
    ];
  };
  
  # Get upstream based on protocol
  getUpstream = protocol:
    if protocol == "plain" then
      if privateDns.enabled then 
        map (u: if (builtins.match "([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)(:[0-9]+)?" u != null || builtins.match "([0-9a-fA-F:]+)(:[0-9]+)?" u != null) then u else "dns://${u}") privateDns.upstreams
      else throw "Plain DNS not available for ${name}"
    else if protocol == "dot" then
      if dot.enabled then [ dot.upstream ] 
      else throw "DoT not available for ${name}"
    else if protocol == "doh" then
      if doh.enabled then [ doh.upstream ] 
      else throw "DoH not available for ${name}"
    else if protocol == "doq" then
      if doq.enabled then [ doq.upstream ] 
      else throw "DoQ not available for ${name}"
    else if protocol == "dnscrypt" then
      if dnscrypt.enabled then [ dnscrypt.stamp ] 
      else throw "DNSCrypt not available for ${name}"
    else throw "Unknown protocol: ${protocol}";
  
  # Get default upstream list
  defaultUpstreams = getUpstream defaultProtocol;
  
  # Create the script with support for all enabled protocols
  script = pkgs.writeShellScript "dnsproxy-${name}" ''
    PROTOCOL="$1"
    shift 1 2>/dev/null || true
    
    if [ "$PROTOCOL" = "dot" ] || [ "$PROTOCOL" = "doh" ] || [ "$PROTOCOL" = "doq" ] || [ "$PROTOCOL" = "dnscrypt" ] || [ "$PROTOCOL" = "plain" ]; then
      # If valid protocol specified, use it
      case "$PROTOCOL" in
        ${if privateDns.enabled then ''
        "plain")
          UPSTREAMS="${builtins.concatStringsSep " --upstream=" (getUpstream "plain")}"
          ;;
        '' else ""}
        ${if dot.enabled then ''
        "dot")
          UPSTREAMS="${builtins.elemAt (getUpstream "dot") 0}"
          ;;
        '' else ""}
        ${if doh.enabled then ''
        "doh")
          UPSTREAMS="${builtins.elemAt (getUpstream "doh") 0}"
          ;;
        '' else ""}
        ${if doq.enabled then ''
        "doq")
          UPSTREAMS="${builtins.elemAt (getUpstream "doq") 0}"
          ;;
        '' else ""}
        ${if dnscrypt.enabled then ''
        "dnscrypt")
          UPSTREAMS="${builtins.elemAt (getUpstream "dnscrypt") 0}"
          ;;
        '' else ""}
      esac
      shift 1 2>/dev/null || true
    else
      # Default protocol
      PROTOCOL="${defaultProtocol}"
      UPSTREAMS="${builtins.concatStringsSep " --upstream=" defaultUpstreams}"
    fi
    
    if [ $# -eq 0 ] || [[ "$*" == *--help* ]]; then
      # If no args or help flag, run with our default arguments
      exec ${dnsproxy}/bin/dnsproxy \
        --listen=${listenAddr} \
        ${if ipv6.enabled then ''--listen=${ipv6.listenAddr}'' else ""} \
        --port=${toString listenPort} \
        --upstream=$UPSTREAMS \
        --cache \
        --cache-size=4096 \
        --dns64 \
        --dns64-prefix="${dns64.prefix}" \
        ${if bogusNX.enabled then ''--bogus-nxdomain=${builtins.concatStringsSep "," bogusNX.domains}'' else ""} \
        "$@"
    else
      # Otherwise, use user provided arguments
      exec ${dnsproxy}/bin/dnsproxy "$@"
    fi
  '';
in
{
  app = {
    "dnsproxy-${name}" = {
      type = "app";
      program = "${script}";
    };
  };

  systemdService = {
    "dnsproxy-${name}" = {
      description = "${description} (${listenAddr}:${toString listenPort})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${dnsproxy}/bin/dnsproxy \
            --listen=${listenAddr} \
            ${if ipv6.enabled then "\\\n            --listen=${ipv6.listenAddr}" else ""} \
            --port=${toString listenPort} \
            ${builtins.concatStringsSep " \\\n            " (map (upstream: "--upstream=${upstream}") defaultUpstreams)} \
            --cache \
            --cache-size=4096 \
            --dns64 \
            --dns64-prefix="${dns64.prefix}" \
            ${if bogusNX.enabled then "\\\n            --bogus-nxdomain=${builtins.concatStringsSep "," bogusNX.domains}" else ""}
        '';
        Restart = "always";
        DynamicUser = true;
      };
    };
  };
  
  # Provider IP address information
  providerInfo = {
    name = name;
    description = description;
    listenAddr = listenAddr;
    listenPort = listenPort;
    ipv6 = ipv6;
    upstreamAddresses = {
      plain = privateDns.upstreams;
      dot = [];
      doh = [];
      doq = [];
      dnscrypt = [];
    };
    dns64 = dns64;
    bogusNX = bogusNX;
  };
} 