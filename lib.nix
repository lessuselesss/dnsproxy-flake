{ pkgs, dnsproxy, name, listenAddr, upstreams }:

let
  # Core default configuration - these are the base defaults that apply to all providers
  coreDefaults = {
    # Basic configuration
    port = 53;
    configPath = null;
    output = null;
    
    # TLS configuration
    tlsCrt = null;
    tlsKey = null;
    tlsMinVersion = null;
    tlsMaxVersion = null;
    
    # HTTPS configuration
    httpsPort = null;
    httpsServerName = null;
    httpsUserinfo = null;
    
    # DNSCrypt configuration
    dnscryptPort = null;
    dnscryptConfig = null;
    
    # TLS configuration
    tlsPort = null;
    
    # QUIC configuration
    quicPort = null;
    
    # Cache configuration
    cache = true;
    cacheOptimistic = false;
    cacheMinTtl = 60;
    cacheMaxTtl = 3600;
    cacheSize = 4096;
    
    # Rate limiting
    ratelimit = null;
    ratelimitSubnetLenIpv4 = null;
    ratelimitSubnetLenIpv6 = null;
    
    # Performance tuning
    udpBufSize = null;
    maxGoRoutines = null;
    timeout = "10s";
    
    # Security features
    insecure = false;
    refuseAny = false;
    
    # IPv6 configuration
    ipv6Disabled = false;
    
    # DNS64 configuration
    dns64 = false;
    dns64Prefix = null;
    
    # Private DNS configuration
    usePrivateRdns = false;
    privateRdnsUpstream = [];
    privateSubnets = [];
    
    # Hosts file configuration
    hostsFileEnabled = false;
    hostsFiles = [];
    
    # Bogus NXDOMAIN configuration
    bogusNxdomain = [];
    
    # Debugging and monitoring
    pprof = false;
    version = false;
    verbose = false;
    
    # Protocol support
    http3 = false;
  };

  # Protocol-specific defaults
  protocolDefaults = {
    # Plain DNS defaults
    plainDns = {
      enabled = true;
      upstreams = [];
    };
    
    # DoT (DNS over TLS) defaults
    dot = {
      enabled = false;
      upstream = "";
    };
    
    # DoH (DNS over HTTPS) defaults
    doh = {
      enabled = false;
      upstream = "";
    };
    
    # DoQ (DNS over QUIC) defaults
    doq = {
      enabled = false;
      upstream = "";
    };
    
    # DNSCrypt defaults
    dnscrypt = {
      enabled = false;
      stamp = "";
    };
  };

  # IPv6 configuration defaults
  ipv6Defaults = {
    enabled = true;
    listenAddr = "::1";
  };

  # DNS64 configuration defaults
  dns64Defaults = {
    enabled = false;
    prefix = "64:ff9b::";
  };

  # DDNS configuration defaults
  ddnsDefaults = {
    enabled = false;
    provider = "";
    domain = "";
    username = "";
    password = "";
  };

  # Bogus NX domain defaults
  bogusNXDefaults = {
    enabled = false;
    domains = [];
  };

  # Helper function to merge configurations with defaults
  mergeWithDefaults = base: overrides:
    let
      # Merge two attribute sets recursively
      recursiveMerge = a: b:
        if builtins.isAttrs a && builtins.isAttrs b then
          builtins.mapAttrs (name: value:
            if b ? ${name} then
              if builtins.isAttrs value && builtins.isAttrs b.${name} then
                recursiveMerge value b.${name}
              else
                b.${name}
            else
              value
          ) a
        else
          b;
    in
      recursiveMerge base overrides;

  # Create the complete default configuration
  defaultConfig = mergeWithDefaults coreDefaults {
    # Merge protocol defaults
    plainDns = protocolDefaults.plainDns;
    dot = protocolDefaults.dot;
    doh = protocolDefaults.doh;
    doq = protocolDefaults.doq;
    dnscrypt = protocolDefaults.dnscrypt;
    
    # Merge other defaults
    ipv6 = ipv6Defaults;
    dns64 = dns64Defaults;
    ddns = ddnsDefaults;
    bogusNX = bogusNXDefaults;
  };

  # Helper function to build command line arguments
  buildArgs = config: let
    # Convert boolean to string
    boolToStr = b: if b then "true" else "false";
    
    # Build argument if value is not null
    buildArg = name: value:
      if value == null then "" else
      if builtins.isBool value then "--${name}=${boolToStr value}" else
      if builtins.isList value then builtins.concatStringsSep " " (map (v: "--${name}=${v}") value) else
      "--${name}=${value}";
    
    # Filter out null values and build arguments
    args = builtins.filter (x: x != "") (builtins.attrValues (builtins.mapAttrs buildArg config));
  in
    builtins.concatStringsSep " \\\n      " args;

  # Build the complete command
  buildCommand = config: ''
    ${dnsproxy}/bin/dnsproxy \
      --listen=${listenAddr} \
      --port=${toString config.port} \
      ${builtins.concatStringsSep " \\\n      " (map (upstream: "--upstream=${upstream}") upstreams)} \
      ${buildArgs config} \
      --log
  '';

  # Create the script with all configuration options
  createScript = config: pkgs.writeShellScript "dnsproxy-${name}" ''
    exec ${buildCommand config}
  '';

  # Create the systemd service
  createSystemdService = config: {
    description = "DNS Proxy for ${name} (${listenAddr})";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = buildCommand config;
      Restart = "always";
      DynamicUser = true;
    };
  };

in
{
  inherit createScript createSystemdService defaultConfig mergeWithDefaults;
} 