{ pkgs, dnsproxy }:

let
  # Import the default module which includes all providers
  defaultModule = import ./default.nix { inherit pkgs dnsproxy; };
  
  # Get provider info from the default module
  providerSummary = defaultModule.providerInfo;
  
  # Add static information for providers without providerInfo attribute
  # This section can be removed once all providers have providerInfo attributes
  missingProvidersInfo = rec {
    # We need this fallback only if some providers don't have providerInfo
    # The structure below is left as a template
    fallback = {
      name = "fallback";
      description = "Fallback template - not used";
      listenAddr = "127.0.0.1";
      listenPort = 53;
      ipv6 = {
        enabled = false;
        listenAddr = "::1";
      };
      upstreamAddresses = {
        plain = [];
        dot = [];
        doh = [];
        doq = [];
        dnscrypt = [];
      };
    };
  };
  
  # Filter out null values from providerInfo and merge with missingProvidersInfo
  combinedProviderInfo = builtins.removeAttrs providerSummary ["unknown"] // missingProvidersInfo;
  
  # Markdown documentation generator
  markdownDoc = pkgs.writeTextFile {
    name = "dns-providers-summary.md";
    text = ''
      # DNS Providers Summary
      
      This document lists all the available DNS providers with their IP addresses and supported protocols.
      
      ## Provider Overview
      
      | Provider | Listen Address | IPv6 Listen | Port | Plain DNS | DoT | DoH | DoQ | DNSCrypt |
      |----------|---------------|-------------|------|-----------|-----|-----|-----|----------|
      ${builtins.concatStringsSep "\n" (builtins.attrValues (builtins.mapAttrs (name: info: 
        "| ${info.name} | ${info.listenAddr} | " +
        "${if info.ipv6.enabled then info.ipv6.listenAddr else "✗"} | " +
        "${toString info.listenPort} | " +
        "${if builtins.length info.upstreamAddresses.plain > 0 then "✓" else "✗"} | " + 
        "${if builtins.length info.upstreamAddresses.dot > 0 then "✓" else "✗"} | " +
        "${if builtins.length info.upstreamAddresses.doh > 0 then "✓" else "✗"} | " +
        "${if builtins.length info.upstreamAddresses.doq > 0 then "✓" else "✗"} | " +
        "${if builtins.length info.upstreamAddresses.dnscrypt > 0 then "✓" else "✗"} |"
      ) combinedProviderInfo))}
      
      ## Detailed Provider Configurations
      
      ${builtins.concatStringsSep "\n\n" (builtins.attrValues (builtins.mapAttrs (name: info: ''
      ### ${info.name}
      
      **Description**: ${info.description}
      **Listen Address**: ${info.listenAddr}:${toString info.listenPort}
      **IPv6 Listen**: ${if info.ipv6.enabled then info.ipv6.listenAddr else "Not enabled"}
      
      #### Supported Protocols:
      
      ${if builtins.length info.upstreamAddresses.plain > 0 then ''
      - **Plain DNS**:
        - IPv4: ${builtins.concatStringsSep ", " (builtins.filter (x: builtins.match "([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)" x != null) info.upstreamAddresses.plain)}
        - IPv6: ${if builtins.length (builtins.filter (x: builtins.match "([0-9a-fA-F:]+)" x != null) info.upstreamAddresses.plain) > 0 then builtins.concatStringsSep ", " (builtins.filter (x: builtins.match "([0-9a-fA-F:]+)" x != null) info.upstreamAddresses.plain) else "None"}
      '' else ""}
      ${if builtins.length info.upstreamAddresses.dot > 0 then ''
      - **DNS over TLS (DoT)**: ${builtins.concatStringsSep ", " info.upstreamAddresses.dot}
      '' else ""}
      ${if builtins.length info.upstreamAddresses.doh > 0 then ''
      - **DNS over HTTPS (DoH)**: ${builtins.concatStringsSep ", " info.upstreamAddresses.doh}
      '' else ""}
      ${if builtins.length info.upstreamAddresses.doq > 0 then ''
      - **DNS over QUIC (DoQ)**: ${builtins.concatStringsSep ", " info.upstreamAddresses.doq}
      '' else ""}
      ${if builtins.length info.upstreamAddresses.dnscrypt > 0 then ''
      - **DNSCrypt**: ${builtins.concatStringsSep ", " info.upstreamAddresses.dnscrypt}
      '' else ""}
      '') combinedProviderInfo))}
      
      ## Examples
      
      ### IPv6 Configuration Example
      
      ```nix
      # IPv6 listen configuration
      ipv6 = {
        enabled = true;
        listenAddr = "::1"; # IPv6 localhost
        # Alternatively, you could use a unique IPv6 address on your network
        # listenAddr = "fd00::64"; # Example of ULA (Unique Local Address)
      };
      
      # Plain DNS configuration with IPv6 support
      plainDns = {
        enabled = true;
        upstreams = [
          # IPv4 addresses
          "8.8.8.8"
          "8.8.4.4"
          # IPv6 addresses
          "2001:4860:4860::8888"
          "2001:4860:4860::8844"
        ];
      };
      ```
      
      ### DNSCrypt Configuration Example
      
      ```nix
      dnscrypt = {
        enabled = true;
        # Sample DNSCrypt stamp for Google
        stamp = "sdns://AQcAAAAAAAAAEDguOC44Ljg6ODQ0My9kb2gPZG5zLmdvb2dsZS5jb20";
      };
      ```
      
      ### DNS64 Configuration Example
      
      DNS64 is used in IPv6-only networks to synthesize IPv6 addresses for IPv4-only resources:
      
      ```nix
      dns64 = {
        enabled = true;
        prefix = "64:ff9b::"; # Standard DNS64 prefix
      };
      ```
      
      ### Bogus NX Domain Example
      
      Bogus NX domains allow you to redirect non-existent domains to a specific IP:
      
      ```nix
      bogusNX = {
        enabled = true;
        domains = [
          "example.invalid"
          "test.example.bogus"
          "non-existent-subdomain.local"
        ];
      };
      ```
      
      ### DDNS Configuration Example
      
      Dynamic DNS configuration for automatically updating DNS records:
      
      ```nix
      ddns = {
        enabled = true;
        provider = "domains.google.com";
        domain = "example.com";
        username = "username";
        password = "password";
      };
      ```
    '';
  };
  
in
{
  summary = combinedProviderInfo;
  markdown = markdownDoc;
} 