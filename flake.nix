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
        
        # Import all providers
        providers = import ./modules/providers { inherit pkgs dnsproxy; };
      in
      {
        packages.default = dnsproxy;
        
        # Default app is just the plain dnsproxy
        apps.default = {
          type = "app";
          program = "${dnsproxy}/bin/dnsproxy";
        };
        
        # Add all provider apps
        apps = providers.apps;
        
        # NixOS module
        nixosModules.dnsproxy-providers = providers.nixosModule;
      }
    );
}
