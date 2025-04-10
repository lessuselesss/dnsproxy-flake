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
        dnsproxy = import ./modules/package.nix { inherit pkgs; };
        
        # Create a default wrapper script
        defaultScript = pkgs.writeShellScript "dnsproxy-default" ''
          exec ${dnsproxy}/bin/dnsproxy "$@"
        '';
        
        # Import all providers from default.nix
        providers = import ./modules/default.nix { inherit pkgs dnsproxy; };
        
        # Import the loopback setup app
        setupLoopback = import ./modules/setup-loopback.nix { inherit pkgs; };
        
        # Import the test proxy
        testProxy = import ./modules/test-proxy.nix { inherit pkgs dnsproxy; };
        
        # Import provider summary for documentation
        providerSummary = import ./modules/provider-summary.nix { inherit pkgs dnsproxy; };
      in
      {
        packages = {
          default = dnsproxy;
          providerSummaryDoc = providerSummary.markdown;
        };
        
        # Add all provider apps from the central providers module
        apps = providers.apps // {
          default = {
            type = "app";
            program = "${defaultScript}";
          };
          setup-loopback = setupLoopback;
          test-proxy = testProxy;
        };
        
        # Expose provider information
        providerInfo = providerSummary.summary;
        
        # NixOS module
        nixosModules.dnsproxy-providers = providers.nixosModule;
      }
    );
}
