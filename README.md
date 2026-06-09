# ⛧ volinit

![volinit banner — LowCache chip art rendered in a terminal](assets/volinitscreenshot.png)

> LowCache, High Throughput

`volinit` is a high-performance shell initiation banner written in Nim. Unlike traditional "fetch" tools, it is designed as the graphical manifestation of a new terminal session, providing immediate branding, high-impact ASCII art, and essential system telemetry.

## ⚡ Features

- **Dissected ASCII Architecture**: Dynamically injects branding banners into complex ASCII art blocks.
- **TrueColor Support**: Utilizes specific TrueColor palettes extracted from custom artwork.
- **Lightweight & Fast**: Compiled Nim binary with zero runtime dependencies.
- **Nix-Native**: Fully Flake-enabled for seamless integration into NixOS configurations.
- **Robust Telemetry**: Graceful fallbacks for system info (OS, Kernel, Uptime, Shell).

## 🚀 Quick Start

Run it immediately without installing:

```bash
nix run github:lowcache/volinit
```

## 🛠️ Installation (NixOS Flake)

1. Add it to your `flake.nix` inputs:

```nix
inputs.volinit.url = "github:lowcache/volinit";
```

2. Add the package to your `home-manager` or system packages:

```nix
environment.systemPackages = [
  inputs.volinit.packages.${system}.default
];
```

3. Trigger it in your shell configuration (e.g., `fish`):

```fish
if status is-interactive
    volinit
end
```

## 🎨 Configuration

The tool embeds assets at compile-time for maximum speed. To customize the ASCII art or tagline, modify `assets/lowcacheascii` and `src/volinit.nim` respectively, then rebuild the derivation.

---
*lowcache 2026*
