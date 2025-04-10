{ pkgs, dnsproxy }:

let
  name = "cleanbrowsing";
  listenAddr = "127.145.97.171";
  upstreams = [
    "dns://185.228.168.9"
    "dns://185.228.169.9"
    "dns://[2001:1608:10:25::1c04:b12f]"  # DNS.WATCH IPv6
    "dns://[2001:1608:10:25::9249:d69b]"  # DNS.WATCH IPv6
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
      description = "DNS Proxy for CleanBrowsing (${listenAddr})";
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