{ pkgs, dnsproxy }:

let
  # Basic provider information
  name = "google";
  listenAddr = "127.8.8.88"; # Mnemonic IP matching Google's 8.8.8.8
  description = "DNS Proxy for Google";
  
  # Plain DNS configuration
  plainDns = {
    enabled = true;
    upstreams = [
      "8.8.8.8"
      "8.8.4.4"
    ];
  };
  
  # DoT (DNS over TLS) configuration
  dot = {
    enabled = true;
    upstream = "tls://dns.google";
  };
  
  # DoH (DNS over HTTPS) configuration
  doh = {
    enabled = true;
    upstream = "https://dns.google/dns-query";
  };
  
  # DoQ (DNS over QUIC) configuration
  doq = {
    enabled = true;
    upstream = "quic://dns.google";
  };
  
  # DNSCrypt configuration
  dnscrypt = {
    enabled = false;
    stamp = "";
  };
  
  # Default protocol to use (plain, dot, doh, doq, dnscrypt)
  defaultProtocol = "plain";
  
  # Get upstream based on protocol
  getUpstream = protocol:
    if protocol == "plain" then
      if plainDns.enabled then 
        map (u: if (builtins.match "([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)(:[0-9]+)?" u != null) then u else "dns://${u}") plainDns.upstreams
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
        --port=53 \
        --upstream=$UPSTREAMS \
        --cache \
        --cache-size=4096 \
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
      description = "${description} (${listenAddr})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${dnsproxy}/bin/dnsproxy \
            --listen=${listenAddr} \
            --port=53 \
            ${builtins.concatStringsSep " \\\n            " (map (upstream: "--upstream=${upstream}") defaultUpstreams)} \
            --cache \
            --cache-size=4096
        '';
        Restart = "always";
        DynamicUser = true;
      };
    };
  };
} 