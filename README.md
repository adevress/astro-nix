## Summary

Collection of Nix recipe for Astronomy & Radio-Astronomy usage


## Usage

1- Install Nix 

    - **Case 1**: You do have root access on your machine
        Follow [these instructions](https://nixos.org/download/#download-nix)
    
    
    - **Case 2**: You do not have root access (e.g HPC cluster)
        Follow [these instructions](./doc/rootless-nix.md)


 
2- Clone this repository

3- Use it !

### Usage example I: casacore

Install casacore into a environment named `venv1`

```bash
# install casacore 
nix-env -p venv1 -f ./ -iA casacore
# execute it
./venv1/bin/readms
```

### Usage example II: wsclean

Install wsclean into a environment named `venv2`

```bash
# install wsclean 
nix-env -p venv2 -f ./ -iA wsclean
# execute it
./venv2/bin/wsclean
```