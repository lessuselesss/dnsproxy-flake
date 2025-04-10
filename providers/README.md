# DNS Proxy Configuration Guide

This guide explains the configuration options available for the DNS proxy service.

## Basic Configuration

- `name`: The name of the DNS proxy instance (default: "dnsproxy")
- `listenAddr`: The address to listen on (default: "127.0.0.1")
- `upstreams`: List of DNS upstream servers to use (required)

## Cache Configuration

- `cache`: Enable DNS caching (default: true)
- `cacheSize`: Maximum number of cached responses (default: 4096)
- `cacheMinTtl`: Minimum TTL for cached responses (default: 0)
- `cacheMaxTtl`: Maximum TTL for cached responses (default: 86400)

## Performance Tuning

- `timeout`: Query timeout duration (default: "10s")
- `ratelimit`: Maximum number of requests per second (default: 0, disabled)
- `ratelimitSubnetLenIpv4`: IPv4 subnet length for rate limiting (default: 24)
- `ratelimitSubnetLenIpv6`: IPv6 subnet length for rate limiting (default: 56)

## Security Features

- `refuseAny`: Refuse ANY queries (default: false)
- `usePrivateRdns`: Enable private reverse DNS lookups (default: false)
- `privateSubnets`: List of private subnets for reverse DNS (default: common private ranges)
- `ipv6Disabled`: Disable IPv6 support (default: false)

## Protocol Support

- `http3`: Enable HTTP/3 support (default: false)

## Example Upstream Formats

The DNS proxy supports various upstream formats:

- Standard DNS: `dns://9.9.9.9`
- DNS over TLS: `tls://1.1.1.1`
- DNS over HTTPS: `https://dns.google/dns-query`
- DNS over QUIC: `quic://dns.adguard.com`
- DNSCrypt: `sdns://...`

IPv6 addresses should be enclosed in square brackets:
- `dns://[2620:fe::fe]`
- `tls://[2606:4700:4700::1111]`

## Example Configuration

See `example.nix` for a basic configuration example. The example shows how to:
1. Import the library functions
2. Configure basic settings
3. Create a script and systemd service
4. Enable the service in your NixOS configuration 