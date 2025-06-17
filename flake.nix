{
  description = "A Nix flake for dnsproxy with dynamic DNS configurations and encrypted DNS providers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Import the dnsproxy package
        dnsproxy = import ./providers/package.nix { inherit pkgs; };

        # Wrapper script to dynamically handle arguments
        dnsProxyScript = pkgs.writeShellScript "dns-proxy-runner" ''
          # Parse arguments
          AppBinaryPackageName="$1"
          ProviderName="$2"
          Command="$3"

          # Load provider defaults based on ProviderName
          case "$ProviderName" in
            "providerA")
              DNS="dns://8.8.8.8"
              Interface="eth0"
              LogLevel="info"
              ;;
            "providerB")
              DNS="dns://1.1.1.1"
              Interface="wlan0"
              LogLevel="debug"
              ;;
            *)
              echo "Unknown provider: $ProviderName"
              exit 1
              ;;
          esac

          # Execute the command with provider defaults
          exec ${dnsproxy}/bin/dnsproxy --upstream $DNS --interface $Interface --log-level $LogLevel "$AppBinaryPackageName" $Command
        '';

        # Import all providers from default.nix
        providers = import ./providers/default.nix { inherit pkgs dnsproxy; };

      in
      {
        packages = {
          default = dnsproxy;
        };

        # Add all provider apps from the central providers module
        apps = providers.apps // {
          dns-proxy = {
            type = "app";
            program = "${dnsProxyScript}";
          };
        };

        # NixOS module
        nixosModules.dnsproxy-providers = providers.nixosModule;
      }
    );
}