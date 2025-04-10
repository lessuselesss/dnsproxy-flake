{ pkgs, dnsproxy }:

let
  name = "quad9";
  listenAddr = "127.9.9.99";
  upstreams = [
    "dns://9.9.9.9"
    "dns://149.112.112.112"
    # Uncomment the following lines to enable DNS over TLS
    # "tls://dns.quad9.net"  # Quad9 DoT
    # "tls://[2620:9f::1]"    # Quad9 IPv6 DoT
  ];

  # Create the script
  script = pkgs.writeShellScript "dnsproxy-${name}" ''
    exec ${dnsproxy}/bin/dnsproxy \
      --listen=${listenAddr} \
      --port=53 \
      --upstream=${builtins.elemAt upstreams 0} \
      --upstream=${builtins.elemAt upstreams 1} \
      --cache \
      --cache-size=4096 \
      --log
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
      description = "DNS Proxy for Quad9 (${listenAddr})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${dnsproxy}/bin/dnsproxy \
            --listen=${listenAddr} \
            --port=53 \
            --upstream=${builtins.elemAt upstreams 0} \
            --upstream=${builtins.elemAt upstreams 1} \
            --cache \
            --cache-size=4096 \
            --log
        '';
        Restart = "always";
        DynamicUser = true;
      };
    };
  };
} 