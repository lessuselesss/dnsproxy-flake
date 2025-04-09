A Nix flake for running AdGuard's `dnsproxy` with multiple encrypted DNS providers, mapped to mnemonic loopback IPs (e.g., `127.1.1.11` for Cloudflare, `127.8.8.88` for Google). This flake builds `dnsproxy` v0.71.2 and provides a NixOS module to deploy systemd services for each provider.

## Features
- **Encrypted DNS**: Supports DoH, DoT, and DNSCrypt via `dnsproxy`.
- **Mnemonic IPs**: Logical mapping of DNS providers to loopback IPs (e.g., `127.9.9.99` for Quad9).
- **NixOS Integration**: Deploys systemd services for each provider.
- **Tailscale Ready**: Compatible with Tailscale’s split DNS.

## Prerequisites
- **Nix**: Installed with flake support enabled (`experimental-features = nix-command flakes` in `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`).
- **Git**: To clone or manage the repo (optional).
- **NixOS**: Required only if using the NixOS module (otherwise, works on any Nix-supported system).

## Providers and IPs
| Mnemonic IP       | Provider           | Upstream(s)                              | Notes                     |
|-------------------|--------------------|------------------------------------------|---------------------------|
| `127.1.1.11`      | Cloudflare Tor     | `.onion` via Tor                        | Privacy-focused (requires Tor) |
| `127.8.8.88`      | Google             | `8.8.8.8`, `8.8.4.4`                   | General-purpose DNS       |
| `127.9.9.99`      | Quad9              | `9.9.9.9`, `149.112.112.112`           | Malware protection        |
| `127.94.14.14`    | AdGuard            | `94.140.14.14`, `94.140.15.15`         | Ad-blocking DNS           |
| `127.208.67.222`  | OpenDNS            | `208.67.222.222`, `208.67.220.220`     | Filtering options         |
| `127.64.6.64`     | Verisign           | `64.6.64.6`, `64.6.65.6`               | Reliable, no filtering    |
| `127.185.39.10`   | DNS.WATCH          | `84.200.69.80`, `84.200.70.40`         | Privacy, no logging       |
| `127.145.97.171`  | CleanBrowsing      | `185.228.168.9`, `185.228.169.9`       | Family-friendly filtering |
| `127.77.36.11`    | UncensoredDNS      | `89.233.43.71`, `91.239.100.100`       | No censorship             |
| `127.45.45.45`    | NextDNS            | `dns.nextdns.io/<your-id>`             | Customizable (requires ID)|

## Usage

### 1. Clone the Repository (Optional)
```bash
git clone <your-repo-url> dnsproxy-flake
cd dnsproxy-flake
```

Alternatively, use the flake directly from your local path without cloning.

### 2. Build the dnsproxy Binary
```bash
nix build .
```
- Outputs the binary to `./result/bin/dnsproxy`.
- Verify the version:
  ```bash
  ./result/bin/dnsproxy --version
  ```
  Expected output: `dnsproxy 0.71.2`.

### 3. Run dnsproxy Standalone
Test a single instance (e.g., Google DNS):
```bash
./result/bin/dnsproxy --listen=127.0.0.1 --port=5300 --upstream=dns://8.8.8.8
```
Query it:
```bash
dig @127.0.0.1 -p 5300 example.com
```

### 4. Integrate with NixOS
Add this flake to your system’s `flake.nix` and deploy the DNS services.

#### Example System `flake.nix`
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    dnsproxy-flake.url = "path:/path/to/dnsproxy-flake"; # Adjust path
  };
  outputs = { self, nixpkgs, dnsproxy-flake, ... }:
    {
      nixosConfigurations.mySystem = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Adjust for your system
        modules = [
          dnsproxy-flake.nixosModules.dnsproxy-providers
          {
            services.dnsproxy-providers.enable = true;
            # Optional: Customize NextDNS ID
            systemd.services."dnsproxy-nextdns".serviceConfig.ExecStart = ''
              ${dnsproxy-flake.packages.x86_64-linux.default}/bin/dnsproxy \
                --listen=127.45.45.45 \
                --port=53 \
                --upstream=https://dns.nextdns.io/<your-id> \
                --cache \
                --cache-size=4096 \
                --log
            '';
          }
        ];
      };
    };
}
```

#### Apply Configuration
```bash
sudo nixos-rebuild switch --flake .
```

#### Test Services
```bash
dig @127.1.1.11 example.com  # Cloudflare Tor (requires Tor running)
dig @127.8.8.88 example.com  # Google
dig @127.9.9.99 example.com  # Quad9
```
Check logs:
```bash
journalctl -u dnsproxy-google
```

### 5. Configure Tailscale Split DNS
1. Log into the Tailscale admin console (https://login.tailscale.com/admin).
2. Go to **DNS** > **Nameservers**.
3. Add each mnemonic IP as a nameserver (e.g., `127.1.1.11`, `127.8.8.88`).
4. Use **Split DNS** to assign domains:
   - `*.onion` → `127.1.1.11` (Cloudflare Tor).
   - `example.com` → `127.8.8.88` (Google).
   - `ads.example.com` → `127.94.14.14` (AdGuard).
5. If running on a remote Tailscale node, use its Tailscale IP (e.g., `100.x.y.z`) instead.

### 6. Troubleshooting
- **Hash Mismatch**:
  - If `nix build` fails with a hash mismatch:
    ```bash
    nix flake prefetch github:AdguardTeam/dnsproxy/v0.71.2
    ```
    Update `sha256` in `flake.nix` with the new hash.
  - For `vendorHash`, set to `""`, run `nix build`, and use the hash from the error output.
- **No Version Output**:
  - Ensure `ldflags` is set in `flake.nix` as shown.
- **Service Fails**:
  - Check logs: `journalctl -u dnsproxy-<provider>`.

## Customization
- **NextDNS**: Replace `<your-id>` in the `dnsproxy-nextdns` service with your NextDNS config ID.
- **Add Providers**: Extend `systemd.services` in the NixOS module with new providers and IPs.
- **Adjust Cache**: Modify `--cache-size` in `ExecStart` for performance tuning.

## License
- `dnsproxy` is licensed under Apache License 2.0 (see [AdguardTeam/dnsproxy](https://github.com/AdguardTeam/dnsproxy)).
- This flake is provided under the same terms.

---

### Notes
- Replace `<your-repo-url>` with the actual Git URL if you host this publicly.
- The `system` in the NixOS example (`x86_64-linux`) should match your hardware (e.g., `aarch64-linux` for Raspberry Pi, `x86_64-darwin` for macOS if adapting for non-NixOS).
- The README assumes you’ll customize the NextDNS ID
