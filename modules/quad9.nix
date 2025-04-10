{ pkgs, dnsproxy }:

let
  name = "quad9";
  listenAddr = "127.9.9.99";
  upstreams = [
    "dns://9.9.9.9"
    "dns://149.112.112.112"
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