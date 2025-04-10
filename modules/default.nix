{ pkgs, dnsproxy }:

let
  # Import all provider modules
  cloudflare-tor = import ./cloudflare-tor.nix { inherit pkgs dnsproxy; };
  google = import ./google.nix { inherit pkgs dnsproxy; };
  quad9 = import ./quad9.nix { inherit pkgs dnsproxy; };
  adguard = import ./adguard.nix { inherit pkgs dnsproxy; };
  opendns = import ./opendns.nix { inherit pkgs dnsproxy; };
  verisign = import ./verisign.nix { inherit pkgs dnsproxy; };
  dnswatch = import ./dnswatch.nix { inherit pkgs dnsproxy; };
  cleanbrowsing = import ./cleanbrowsing.nix { inherit pkgs dnsproxy; };
  uncensoreddns = import ./uncensoreddns.nix { inherit pkgs dnsproxy; };
  nextdns = import ./nextdns.nix { inherit pkgs dnsproxy; };
  
  # Combine all apps and service definitions
  allProviders = [
    cloudflare-tor
    google
    quad9
    adguard
    opendns
    verisign
    dnswatch
    cleanbrowsing
    uncensoreddns
    nextdns
  ];
in
{
  # Combine all apps into a flat attrset
  apps = builtins.foldl' (acc: provider: acc // provider.app) {} allProviders;
  
  # NixOS module that combines all systemd services
  nixosModule = { config, lib, ... }:
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

        # Combine all systemd services from providers
        systemd.services = builtins.foldl' 
          (acc: provider: acc // provider.systemdService) 
          {} 
          allProviders;

        # Set system resolver to Cloudflare Tor as default
        networking.nameservers = [ "127.1.1.11" ];
        networking.resolvconf.enable = true;
        services.resolved.enable = false; # Avoid conflicts with systemd-resolved
      };
    };
} 