## Summary

Collection of Nix recipe for Astronomy & Radio-Astronomy usage


## Usage

1- Clone this repository

2- Install Nix 

 - **Case 1**: You do have root access on your machine

   2.1 - Follow [these instructions](https://nixos.org/download/#download-nix)

   2.2 - enable flake and nix-command. You can do it with `sudo ./scripts/nix-command-edit.sh`
    
    
 - **Case 2**: You do not have root access (e.g HPC cluster)

   2.1 Follow [these instructions](./doc/rootless-nix.md)


3- Use it !


### Usage example I: casacore

Install and run casacore 

```bash
# download, (compile), install  casacore and get a shell
nix shell -f ./  casacore --command bash
# execute it
readms
```

### Usage example II: wsclean

Install and run wsclean 

```bash
# download, (compile), install wsclean and get a shell
nix shell -f ./  wsclean --command bash
# execute it
wsclean

```


## Tests and support

Tested on:

- Linux Desktop/Laptop (Ubuntu; Intel CPU; x86_64; root)
- EPFL Kuma (Red hat; AMD + GPU Nvidia; x86_64; rootless)
- CSCS Daint (Red hat; Grace + Hopper GPU; Aarch64; rootless)
- EPFL Manticore (ubuntu; Grace + Hopper GPU; Aarch64; rootless) 


## Binary support

It is technically doable to support binary shipping for this repository. But not done yet
