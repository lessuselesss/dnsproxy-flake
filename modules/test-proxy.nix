{ pkgs, dnsproxy }:

let
  script = pkgs.writeShellScript "dnsproxy-test" ''
    exec ${dnsproxy}/bin/dnsproxy \
      --listen=127.0.0.1 \
      --port=5353 \
      --upstream=8.8.8.8 \
      --upstream=1.1.1.1 \
      --cache \
      --cache-size=4096 \
      "$@"
  '';
in
{
  type = "app";
  program = "${script}";
} 