{ pkgs, dnsproxy, name, listenAddr, upstreams }:

let
  # Core default configuration - these are the base defaults that apply to all providers
  coreDefaults = {
    # Basic configuration
    port = 53;
    "config-path" = null;
    output = null;
    
    # TLS configuration
    "tls-crt" = null;
    "tls-key" = null;
    "tls-min-version" = null;
    "tls-max-version" = null;
    
    # HTTPS configuration
    "https-port" = null;
    "https-server-name" = null;
    "https-userinfo" = null;
    
    # DNSCrypt configuration
    "dnscrypt-port" = null;
    "dnscrypt-config" = null;
    
    # TLS configuration
    "tls-port" = null;
    
    # QUIC configuration
    "quic-port" = null;
    
    # Cache configuration
    cache = true;
    "cache-optimistic" = false;
    "cache-min-ttl" = 60;
    "cache-max-ttl" = 3600;
    "cache-size" = 4096;
    
    # Rate limiting
    ratelimit = null;
    "ratelimit-subnet-len-ipv4" = null;
    "ratelimit-subnet-len-ipv6" = null;
    
    # Performance tuning
    "udp-buf-size" = null;
    "max-go-routines" = null;
    timeout = "10s";
    
    # Security features
    insecure = false;
    "refuse-any" = false;
    
    # IPv6 configuration
    "ipv6-disabled" = false;
    
    # DNS64 configuration
    dns64 = false;
    "dns64-prefix" = null;
    
    # Private DNS configuration
    "use-private-rdns" = false;
    "private-rdns-upstream" = [];
    "private-subnets" = [];
    
    # Hosts file configuration
    "hosts-file-enabled" = false;
    "hosts-files" = [];
    
    # Bogus NXDOMAIN configuration
    "bogus-nxdomain" = [];
    
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

  # Build the complete command
  buildCommand = config: let
    # Convert boolean to string
    boolToStr = b: if b then "true" else "false";
    
    # Build argument if value is not null
    buildArg = name: value:
      if value == null then "" else
      if builtins.isBool value then (if value then "--${name}" else "") else
      if builtins.isList value then builtins.concatStringsSep " " (map (v: "--${name}=${toString v}") value) else
      "--${name}=${toString value}";
    
    # Attributes that are handled specially and should be removed
    specialAttrs = [
      "dns64"
      "ipv6"
      "plainDns"
      "dot"
      "doh"
      "doq"
      "dnscrypt"
      "ddns"
      "bogusNX"
      "upstream"
    ];
    
    # Build protocol-specific arguments
    protocolArgs = 
      (map (upstream: "--upstream=${upstream}") upstreams) ++
      (if config ? dot && config.dot.enabled then ["--upstream=${config.dot.upstream}"] else []) ++
      (if config ? doh && config.doh.enabled then ["--upstream=${config.doh.upstream}"] else []) ++
      (if config ? doq && config.doq.enabled then ["--upstream=${config.doq.upstream}"] else []) ++
      (if config ? dnscrypt && config.dnscrypt.enabled then ["--upstream=${config.dnscrypt.stamp}"] else []);
    
    # Build IPv6 arguments
    ipv6Args = if config ? ipv6 && config.ipv6.enabled then ["--listen=${config.ipv6.listenAddr}"] else [];
    
    # Build DNS64 arguments
    dns64Args = if config ? dns64 && config.dns64.enabled then ["--dns64" "--dns64-prefix=${config.dns64.prefix}"] else [];
    
    # Build bogus NX domain arguments
    bogusNXArgs = if config ? bogusNX && config.bogusNX.enabled && config.bogusNX.domains != [] 
      then ["--bogus-nxdomain=${builtins.concatStringsSep "," config.bogusNX.domains}"] 
      else [];
    
    # Combine all arguments
    allArgs = ["--listen=${listenAddr}" "--port=${toString config.port}"] ++
      protocolArgs ++
      ipv6Args ++
      dns64Args ++
      bogusNXArgs ++
      (builtins.filter (x: x != "") 
        (builtins.attrValues 
          (builtins.mapAttrs buildArg 
            (builtins.removeAttrs config specialAttrs))));
  in ''
    ${dnsproxy}/bin/dnsproxy \
      ${builtins.concatStringsSep " \\\n      " allArgs}
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

  # Create the appropriate service configuration based on the OS
  createService = config: let
    isDarwin = pkgs.stdenv.isDarwin;
    serviceConfig = if isDarwin then {
      # macOS launchd service
      type = "app";
      program = pkgs.writeShellScript "dnsproxy-${name}-launchd" ''
        #!/bin/sh
        if [ "$1" = "install" ]; then
          cat > /Library/LaunchDaemons/com.dnsproxy.${name}.plist << EOF
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.dnsproxy.${name}</string>
            <key>ProgramArguments</key>
            <array>
                <string>${dnsproxy}/bin/dnsproxy</string>
                ${builtins.concatStringsSep "\n" (map (arg: "                <string>${arg}</string>") (builtins.filter (x: x != "") (builtins.split " " (builtins.replaceStrings ["\\"] [""] (builtins.replaceStrings ["\n"] [" "] (buildCommand config))))))}
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardErrorPath</key>
            <string>/var/log/dnsproxy-${name}.log</string>
            <key>StandardOutPath</key>
            <string>/var/log/dnsproxy-${name}.log</string>
        </dict>
        </plist>
        EOF
          launchctl load /Library/LaunchDaemons/com.dnsproxy.${name}.plist
        elif [ "$1" = "uninstall" ]; then
          launchctl unload /Library/LaunchDaemons/com.dnsproxy.${name}.plist
          rm /Library/LaunchDaemons/com.dnsproxy.${name}.plist
        else
          exec ${buildCommand config}
        fi
      '';
    } else {
      # Linux systemd service
      type = "app";
      program = pkgs.writeShellScript "dnsproxy-${name}-systemd" ''
        #!/bin/sh
        if [ "$1" = "install" ]; then
          cat > /etc/systemd/system/dnsproxy-${name}.service << EOF
        [Unit]
        Description=DNS Proxy for ${name} (${listenAddr})
        After=network.target

        [Service]
        ExecStart=${buildCommand config}
        Restart=always
        DynamicUser=true

        [Install]
        WantedBy=multi-user.target
        EOF
          systemctl daemon-reload
          systemctl enable dnsproxy-${name}
          systemctl start dnsproxy-${name}
        elif [ "$1" = "uninstall" ]; then
          systemctl stop dnsproxy-${name}
          systemctl disable dnsproxy-${name}
          rm /etc/systemd/system/dnsproxy-${name}.service
          systemctl daemon-reload
        else
          exec ${buildCommand config}
        fi
      '';
    };
  in serviceConfig;

in
{
  inherit createScript createSystemdService defaultConfig mergeWithDefaults createService;
} 