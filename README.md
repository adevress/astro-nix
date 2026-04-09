## Summary

Collection of Nix recipe for Astronomy & Radio-Astronomy usage


## Usage

1- Clone this repository

2- Install Nix 

 - **Case 1**: You do have root access on your machine (preferred method)

   2.1 - Install Nix in daemon mode with this command
          ```bash
          sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
          ```

   2.2 - Apply the project configuration with 
          ```bash
          sudo ./scripts/nix-command-edit.sh
          ```
    
 - **Case 2**: You do not have root access (e.g HPC cluster)

   2.1 Follow [these instructions](./doc/rootless-nix.md)

3- Open a new terminal or refresh your shell

4- Use it !


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

### Usage example III: Python environment for radio astronomy

Get a python environment with:
- astropy
- radler
- numpy
- scipy
- matplotlib 

```bash
# download, (compile), install wsclean and get a shell
nix shell -f ./  astroPyEnv --command python
# execute your command
import astropy
...
```



## Tests and support

Tested on:

- Linux Desktop/Laptop (Ubuntu; Intel CPU; x86_64; root)
- EPFL Kuma (Red hat; AMD + GPU Nvidia; x86_64; rootless)
- CSCS Daint (Red hat; Grace + Hopper GPU; Aarch64; rootless)
- EPFL Manticore (ubuntu; Grace + Hopper GPU; Aarch64; rootless) 


## Binary support

It is technically doable to support binary shipping for this repository. But not done yet
