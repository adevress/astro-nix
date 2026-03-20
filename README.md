## Summary

Collection of Nix recipe for Astronomy & Radio-Astronomy usage


## Usage

1- Install Nix following [these instructions](https://nixos.org/download/#download-nix)

2- Clone this repository

3- Use it !

### Usage example I: Casacore

Install casacore into a environment named `venv`

```bash
# install casacore 
nix-env -p venv -f ./ -iA casacore
# execute it
./venv/bin/readms
```
