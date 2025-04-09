{
  description = "A Nix flake for dnsproxy with encrypted DNS providers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        dnsproxy = pkgs.buildGoModule rec {
          pname = "dnsproxy";
          version = "0.71.2";
          src = pkgs.fetchFromGitHub {
            owner = "AdguardTeam";
            repo = "dnsproxy";
            rev = "v${version}";
            sha256 = "sha256-qrJ5m7k5xLgyW8oS2vXOOQeVsoh6xL2eA8qF8z0bX+I=";
          };
          vendorHash = "sha256-xFJBkH/BRKk+qfXQVtuN3rS7o7lS8oWj5f6j5e5f5e4=";
          meta = with pkgs.lib; {
            description = "Simple DNS proxy with DoH, DoT, DoQ, and DNSCrypt support";
            homepage = "https://github.com/AdguardTeam/dnsproxy";
            license = licenses.asl20;
            maintainers = [ maintainers."yourname" ]; # Optional: replace with your name
          };
        };
      in
      {
        packages.default = dnsproxy;
        apps.default = {
          type = "app";
          program = "${dnsproxy}/bin/dnsproxy";
        };
        nixosModules.dnsproxy-providers = { config, lib, pkgs, ... }:
          with lib;
          let
            cfg = config.services.dnsproxy-providers;
          in
          {
            options.services.dnsproxy-providers = {
              enable = mkEnableOption "Enable dnsproxy instances for encrypted DNS providers";
            };

            config = mkIf cfg.enable {
              # Enable Tor for Cloudflare Tor instance
              services.tor = {
                enable = true;
                client.enable = true;
              };

              # Systemd services for each provider
              systemd.services = {
                "dnsproxy-cloudflare-tor" = {
                  description = "DNS Proxy for Cloudflare Tor (127.1.1.11)";
                  after = [ "network.target" "tor.service" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.1.1.11 \
                        --port=53 \
                        --upstream=https://dns4torpnlfs2ifuz2s2yf3fc7rdmsbhm6rw75euj35pac6ap25zgqad.onion/dns-query \
                        --proxy=socks5://127.0.0.1:9050 \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };

                "dnsproxy-google" = {
                  description = "DNS Proxy for Google (127.8.8.88)";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.8.8.88 \
                        --port=53 \
                        --upstream=dns://8.8.8.8 \
                        --upstream=dns://8.8.4.4 \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };

                "dnsproxy-quad9" = {
                  description = "DNS Proxy for Quad9 (127.9.9.99)";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.9.9.99 \
                        --port=53 \
                        --upstream=dns://9.9.9.9 \
                        --upstream=dns://149.112.112.112 \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };

                "dnsproxy-adguard" = {
                  description = "DNS Proxy for AdGuard (127.94.14.14)";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.94.14.14 \
                        --port=53 \
                        --upstream=dns://94.140.14.14 \
                        --upstream=dns://94.140.15.15 \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };

                "dnsproxy-opendns" = {
                  description = "DNS Proxy for OpenDNS (127.208.67.222)";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.208.67.222 \
                        --port=53 \
                        --upstream=dns://208.67.222.222 \
                        --upstream=dns://208.67.220.220 \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };

                "dnsproxy-verisign" = {
                  description = "DNS Proxy for Verisign (127.64.6.64)";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.64.6.64 \
                        --port=53 \
                        --upstream=dns://64.6.64.6 \
                        --upstream=dns://64.6.65.6 \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };

                "dnsproxy-dnswatch" = {
                  description = "DNS Proxy for DNS.WATCH (127.185.39.10)";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.185.39.10 \
                        --port=53 \
                        --upstream=dns://84.200.69.80 \
                        --upstream=dns://84.200.70.40 \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };

                "dnsproxy-cleanbrowsing" = {
                  description = "DNS Proxy for CleanBrowsing (127.145.97.171)";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.145.97.171 \
                        --port=53 \
                        --upstream=dns://185.228.168.9 \
                        --upstream=dns://185.228.169.9 \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };

                "dnsproxy-uncensoreddns" = {
                  description = "DNS Proxy for UncensoredDNS (127.77.36.11)";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.77.36.11 \
                        --port=53 \
                        --upstream=dns://89.233.43.71 \
                        --upstream=dns://91.239.100.100 \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };

                "dnsproxy-nextdns" = {
                  description = "DNS Proxy for NextDNS (127.45.45.45)";
                  after = [ "network.target" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    ExecStart = ''
                      ${dnsproxy}/bin/dnsproxy \
                        --listen=127.45.45.45 \
                        --port=53 \
                        --upstream=https://dns.nextdns.io/<your-id> \
                        --cache \
                        --cache-size=4096 \
                        --log
                    '';
                    Restart = "always";
                    DynamicUser = true;
                  };
                };
              };

              # Set system resolver to Cloudflare Tor as default
              networking.nameservers = [ "127.1.1.11" ];
              networking.resolvconf.enable = true;
              services.resolved.enable = false; # Avoid conflicts with systemd-resolved
            };
          };
      }
    );
}
