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
