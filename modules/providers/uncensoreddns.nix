{ pkgs, dnsproxy }:

let
  name = "uncensoreddns";
  listenAddr = "127.77.36.11";
  upstreams = [
    "dns://89.233.43.71"
    "dns://91.239.100.100"
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
      description = "DNS Proxy for UncensoredDNS (${listenAddr})";
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