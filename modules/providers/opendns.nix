{ pkgs, dnsproxy }:

let
  name = "opendns";
  listenAddr = "127.208.67.222";
  upstreams = [
    "dns://208.67.222.222"
    "dns://208.67.220.220"
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
      description = "DNS Proxy for OpenDNS (${listenAddr})";
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