{ pkgs, dnsproxy }:

let
  name = "google";
  listenAddr = "127.8.8.88";
  upstreams = [
    "dns://8.8.8.8"
    "dns://8.8.4.4"
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
      description = "DNS Proxy for Google (${listenAddr})";
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