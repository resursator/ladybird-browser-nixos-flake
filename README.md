# Ladybird Alpha for NixOS

An unofficial Nix Flake packaging of the [Ladybird](https://github.com/LadybirdBrowser/ladybird) web browser for NixOS, featuring a custom FFmpeg build with Vulkan hardware acceleration and additional dependency patches.

## Features

- Ladybird `2026.47.7`.
- Custom FFmpeg `9.0.2` build:
  - Shared libraries.
  - VP8 and VP9 decoding.
  - AV1 decoding through dav1d.
  - Vulkan hardware acceleration for VP9 and AV1.
- Custom Skia build flags.
- Updated mimalloc dependency (`2.2.7`).
- Separately packaged LLVM libc headers.
- PDF.js integration with Ladybird-specific patches.
- Pinned nixpkgs revision for reproducible builds.

## Requirements

- Nix with Flakes enabled.
- x86_64 Linux.
- Sufficient disk space and memory to build a large C++ project.

## Usage

### Run directly from GitHub

No need to clone the repository:

```bash
nix run github:resursator/ladybird-browser-nixos-flake
```

Nix will fetch the repository, resolve its locked dependencies, build Ladybird and launch it.

### Clone and run locally

Clone the repository:

```bash
git clone https://github.com/resursator/ladybird-browser-nixos-flake.git
cd ladybird-browser-nixos-flake
```

Build and run:

```bash
nix run
```

Alternatively, build the package separately:

```bash
nix build
./result/bin/Ladybird
```

### Run a specific branch or tag

```bash
nix run github:resursator/ladybird-browser-nixos-flake/<REF>
```

Replace `<REF>` with a branch name, tag or commit.

## Using as a Flake Input

Add this repository to another flake:

```nix
{
  inputs.ladybird.url = "github:resursator/ladybird-browser-nixos-flake";

  outputs = { nixpkgs, ladybird, ... }: {
    # Your configuration
  };
}
```

The package is available at:

```nix
ladybird.packages.x86_64-linux.default
```

For example, to install it in a NixOS configuration:

```nix
environment.systemPackages = [
  ladybird.packages.x86_64-linux.default
];
```

## Building

Build the Ladybird package:

```bash
nix build .#ladybird
```

The resulting package will be available in `./result`.

Inspect available flake outputs:

```bash
nix flake show
```

## Updating Dependencies

The nixpkgs input is pinned in `flake.lock` to match the revision used by the author's main NixOS configuration.

Update the lock file:

```bash
nix flake lock
```

To update nixpkgs to a specific revision:

```bash
nix flake lock --override-input nixpkgs \
  github:NixOS/nixpkgs/<REV>
```

## Project Structure

```text
.
├── flake.nix
├── flake.lock
├── README.md
└── pkgs/
    └── ladybird/
        ├── default.nix
        ├── ffmpeg-ladybird.nix
        ├── ladybird-alpha-package.nix
        └── llvm-libc-headers.nix
```

## Disclaimer

This repository provides an unofficial Nix packaging of [Ladybird](https://github.com/LadybirdBrowser/ladybird).

It is not affiliated with, endorsed by or officially supported by the Ladybird project.

Ladybird is experimental software under active development. Build compatibility and functionality may change as upstream sources and dependencies evolve.

## License

Ladybird and its dependencies are distributed under their respective licenses. Refer to the upstream projects for license information.
