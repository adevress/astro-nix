# Astro-Nix

## Summary

Collection of Nix recipes for Astronomy & Radio-Astronomy usage


## Nix installation

1. Clone this repository

2. Install Nix


2.a. Case 1: You have root access on your machine (preferred method)

2.1. Install Nix in daemon mode with this command:

```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
```

2.2. Apply the project configuration with:

```bash
sudo ./scripts/nix-command-edit.sh
```

2.3. Restart the nix daemon:

```bash
sudo systemctl restart nix-daemon
```


2.b. Case 2: You do not have root access (e.g., HPC cluster)

2.1. Follow [these instructions](./doc/rootless-nix.md) 


3. Open a new terminal or refresh your shell

4. Use it!

## Usage

### Usage example I: casacore

Install and run casacore:

```bash
# download, (compile), install casacore and get a shell
nix shell -f ./ casacore --command bash
# execute it
readms
```

### Usage example II: wsclean

Install and run wsclean:

```bash
# download, (compile), install wsclean and get a shell
nix shell -f ./ wsclean --command bash
# execute it
wsclean
```

### Usage example III: Python environment for radio astronomy

Get a Python environment with:
- astropy
- radler
- numpy
- scipy
- matplotlib

```bash
# download, (compile), install astroPyEnv and get a shell
nix shell -f ./ astroPyEnv --command bash
# execute your command
python -c "import astropy; print('Success!')"
```

## Tests and support

Tested on:

- Linux Desktop/Laptop (Ubuntu; Intel CPU; x86_64; root)
- EPFL Kuma (Red Hat; AMD + GPU Nvidia; x86_64; rootless)
- CSCS Daint (Red Hat; Grace + Hopper GPU; AArch64; rootless)
- EPFL Manticore (Ubuntu; Grace + Hopper GPU; AArch64; rootless)

## Binary support

Astro-Nix allows installation from precompiled binary if you are on the following platforms:

- Linux, x86_64