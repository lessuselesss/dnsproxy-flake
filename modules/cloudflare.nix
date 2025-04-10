{ pkgs, dnsproxy }:

let
  # Basic provider information
  name = "cloudflare";
  listenAddr = "127.1.1.1"; # Mnemonic IP matching Cloudflare's 1.1.1.1
  listenPort = 53;
  description = "DNS Proxy for Cloudflare";
  
  # IPv6 listen configuration
  ipv6 = {
    enabled = true;
    listenAddr = "::1"; # IPv6 localhost
  };
  
  # Plain DNS configuration
  plainDns = {
    enabled = true;
    upstreams = [
      # IPv4 addresses
      "1.1.1.1"
      "1.0.0.1"
      # IPv6 addresses
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
    ];
  };
  
  # DoT (DNS over TLS) configuration
  dot = {
    enabled = true;
    upstream = "tls://cloudflare-dns.com";
  };
  
  # DoH (DNS over HTTPS) configuration
  doh = {
    enabled = true;
    upstream = "https://cloudflare-dns.com/dns-query";
  };
  
  # DoQ (DNS over QUIC) configuration
  doq = {
    enabled = true;
    upstream = "quic://cloudflare-dns.com";
  };
  
  # DNSCrypt configuration
  dnscrypt = {
    enabled = true;
    stamp = "sdns://AgcAAAAAAAAABzEuMC4wLjEAEmRucy5jbG91ZGZsYXJlLmNvbQovZG5zLXF1ZXJ5";
  };
  
  # Default protocol to use (plain, dot, doh, doq, dnscrypt)
  defaultProtocol = "plain";
  
  # DNS64 configuration for IPv6-only networks
  dns64 = {
    enabled = false;
    prefix = "64:ff9b::"; # Standard DNS64 prefix
  };
  
  # DDNS (Dynamic DNS) configuration - not applicable for Cloudflare DNS
  ddns = {
    enabled = false;
    provider = "";
    domain = "";
    username = "";
    password = "";
  };
  
  # Bogus NX domain configuration
  bogusNX = {
    enabled = false;
    domains = [];
  };
  
  # Get upstream based on protocol
  getUpstream = protocol:
    if protocol == "plain" then
      if plainDns.enabled then 
        map (u: if (builtins.match "([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)(:[0-9]+)?" u != null || builtins.match "([0-9a-fA-F:]+)(:[0-9]+)?" u != null) then u else "dns://${u}") plainDns.upstreams
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
        ${if plainDns.enabled then ''
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
        ${if dns64.enabled then ''--dns64 --dns64-prefix="${dns64.prefix}"'' else ""} \
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
            ${if dns64.enabled then "\\\n            --dns64 --dns64-prefix=\"${dns64.prefix}\"" else ""} \
            ${if bogusNX.enabled then "\\\n            --bogus-nxdomain=${builtins.concatStringsSep "," bogusNX.domains}" else ""}
        '';
        Restart = "always";
        DynamicUser = true;
        ${if ddns.enabled then ''
        # Environment variables for DDNS configuration
        Environment = [
          "DDNS_PROVIDER=${ddns.provider}"
          "DDNS_DOMAIN=${ddns.domain}"
          "DDNS_USERNAME=${ddns.username}"
          "DDNS_PASSWORD=${ddns.password}"
        ];
        '' else ""}
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
      plain = plainDns.upstreams;
      dot = if dot.enabled then [dot.upstream] else [];
      doh = if doh.enabled then [doh.upstream] else [];
      doq = if doq.enabled then [doq.upstream] else [];
      dnscrypt = if dnscrypt.enabled then [dnscrypt.stamp] else [];
    };
  };
} 