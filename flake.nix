{
  description = "A Nix flake for dnsproxy with dynamic DNS configurations for apps";

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
          Provider="$2"
          Command="$3"
          Action="$4"
          Interface="$5"
          Options="$6"

          # Example: Set DNS provider for app
          if [ "$Action" = "set" ]; then
            exec ${dnsproxy}/bin/dnsproxy --upstream dns://$Provider --interface $Interface $Options "$AppBinaryPackageName"
          elif [ "$Action" = "get" ]; then
            echo "Getting DNS configuration for $AppBinaryPackageName on $Interface"
            # Placeholder for actual `get` implementation
          else
            echo "Invalid action: $Action"
            exit 1
          fi
        '';

      in
      {
        packages = {
          default = dnsproxy;
        };

        apps = {
          dns-proxy = {
            type = "app";
            program = "${dnsProxyScript}";
          };
        };
      }
    );
}

}
  description = "A Nix flake for dnsproxy with encrypted DNS providers";

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
        
        # Create a default wrapper script
        defaultScript = pkgs.writeShellScript "dnsproxy-default" ''
          exec ${dnsproxy}/bin/dnsproxy "$@"
        '';
        
        # Import all providers from default.nix
        providers = import ./providers/default.nix { inherit pkgs dnsproxy; };
        
        # Import the test proxy
        testProxy = import ./providers/test-proxy.nix { inherit pkgs dnsproxy; };
      in
      {
        packages = {
          default = dnsproxy;
        };
        
        # Add all provider apps from the central providers module
        apps = providers.apps // {
          default = {
            type = "app";
            program = "${defaultScript}";
          };
          test-proxy = testProxy;
        };
        
        # NixOS module
        nixosModules.dnsproxy-providers = providers.nixosModule;
      }
    );
}
