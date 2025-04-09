{ pkgs, dnsproxy }:

let
  name = "dnswatch";
  listenAddr = "127.185.39.10";
  upstreams = [
    "dns://84.200.69.80"
    "dns://84.200.70.40"
  ];
in
{
  app = {
    "dnsproxy-${name}" = {
      type = "app";
      program = pkgs.writeShellScript "dnsproxy-${name}" ''
        exec ${dnsproxy}/bin/dnsproxy \
          --listen=${listenAddr} \
          --port=53 \
          --upstream=${builtins.elemAt upstreams 0} \
          --upstream=${builtins.elemAt upstreams 1} \
          --cache \
          --cache-size=4096 \
          --log
      '';
    };
  };

  systemdService = {
    "dnsproxy-${name}" = {
      description = "DNS Proxy for DNS.WATCH (${listenAddr})";
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