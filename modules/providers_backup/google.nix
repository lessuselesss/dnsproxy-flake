{ pkgs, dnsproxy }:

let
  name = "google";
  listenAddr = "127.8.8.88";
  upstreams = [
    "dns://8.8.8.8"
    "dns://8.8.4.4"
  ];

  # Create the script
  script = pkgs.writeShellScript "dnsproxy-${name}" ''
    if [ $# -eq 0 ] || [[ "$*" == *--help* ]]; then
      # If no args or --help flag, run with our default arguments
      exec ${dnsproxy}/bin/dnsproxy \
        --listen=${listenAddr} \
        --port=53 \
        --upstream=${builtins.elemAt upstreams 0} \
        --upstream=${builtins.elemAt upstreams 1} \
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
            --cache-size=4096
        '';
        Restart = "always";
        DynamicUser = true;
      };
    };
  };
} 