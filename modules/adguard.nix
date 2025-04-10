{ pkgs, dnsproxy }:

let
  name = "adguard";
  listenAddr = "127.94.14.14";
  upstreams = [
    "dns://94.140.14.14"
    "dns://94.140.15.15"
    "dns://[2001:db8::1]"
    "dns://[2001:db8::2]"
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
      description = "DNS Proxy for AdGuard (${listenAddr})";
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