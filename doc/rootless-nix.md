## Installation of Nix without root rights


1- Get a static nix binary in your home directory

```bash
mkdir -p ~/bin

curl -L https://hydra.nixos.org/job/nix/maintenance-2.34/buildStatic.nix-cli.$(uname -m)-linux/latest/download-by-type/file/binary-dist -o ~/bin/nix

ln -s ~/bin/nix ~/bin/nix-build
ln -s ~/bin/nix ~/bin/nix-shell

chmod 775 ~/bin/nix
```


2- Setup the appropriate config file for a namespaced installation

```bash
mkdir -p ~/.config/nix

cat > ~/.config/nix/nix.conf << EOF
store = ~/.mynixroot
extra-experimental-features = flakes nix-command
ssl-cert-file = /etc/ssl/ca-bundle.pem
EOF  

```

3- bootstrap basic packages and test it

```
# will take some time
nix search nixpkgs hello
# 
nix run 

```
