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
# download, install (or compile_ casacore and get a shell
nix shell -f ./  casacore --command bash
# execute it
readms
```

### Usage example II: wsclean

Install and run wsclean 

```bash
# download, install (or compile_ casacore and get a shell
nix shell -f ./  wsclean --command bash
# execute it
wsclean

```
