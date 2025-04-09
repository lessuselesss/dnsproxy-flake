{ pkgs, dnsproxy }:

let
  name = "cloudflare-tor";
  listenAddr = "127.1.1.11";
  upstream = "https://dns4torpnlfs2ifuz2s2yf3fc7rdmsbhm6rw75euj35pac6ap25zgqad.onion/dns-query";
  proxy = "socks5://127.0.0.1:9050";
in
{
  app = {
    "dnsproxy-${name}" = {
      type = "app";
      program = pkgs.writeShellScript "dnsproxy-${name}" ''
        exec ${dnsproxy}/bin/dnsproxy \
          --listen=${listenAddr} \
          --port=53 \
          --upstream=${upstream} \
          --proxy=${proxy} \
          --cache \
          --cache-size=4096 \
          --log
      '';
    };
  };

  systemdService = {
    "dnsproxy-${name}" = {
      description = "DNS Proxy for Cloudflare Tor (${listenAddr})";
      after = [ "network.target" "tor.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = ''
          ${dnsproxy}/bin/dnsproxy \
            --listen=${listenAddr} \
            --port=53 \
            --upstream=${upstream} \
            --proxy=${proxy} \
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