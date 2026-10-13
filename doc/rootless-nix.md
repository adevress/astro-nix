## Installation of Nix without root rights


1- Get a static nix binary in your home directory

```bash
mkdir -p ~/bin

curl -L https://hydra.nixos.org/job/nix/maintenance-2.34/buildStatic.nix-cli.$(uname -m)-linux/latest/download-by-type/file/binary-dist -o ~/bin/nix

ln -s ~/bin/nix ~/bin/nix-build
ln -s ~/bin/nix ~/bin/nix-shell
ln -s ~/bin/nix ~/bin/nix-env

chmod 775 ~/bin/nix
```

2- Create your software store directory

Tip: If you are in an HPC system, put the software directory in your project directory.
     Try to avoid putting it on a slow filesystem like NFS.

```bash
# This directory prefix will be where all nix software will be installed
MY_SOFTWARE_STORE=/path/to/your/software/dir

mkdir -p ${MY_SOFTWARE_STORE}

export NIX_USER_ROOT_STORE="$(cd ${MY_SOFTWARE_STORE} && pwd -P)"

# Remove tuned ACL, might cause build failure
setfacl -nb ${NIX_USER_ROOT_STORE}
# correct directory rights
chmod 755 ${NIX_USER_ROOT_STORE}
# Remove -s, for reproducibility reasons
chmod g-s ${NIX_USER_ROOT_STORE}

```


3- Set up the appropriate config file for a namespaced installation

```bash
mkdir -p ~/.config/nix

# Resolve the distribution-specific CA bundle
# (Debian/Ubuntu/Arch/Alpine, RHEL/Fedora, openSUSE)
CA_BUNDLE=""
for f in /etc/ssl/certs/ca-certificates.crt \
         /etc/pki/tls/certs/ca-bundle.crt \
         /etc/ssl/ca-bundle.pem; do
  [ -e "$f" ] && CA_BUNDLE="$f" && break
done
[ -n "$CA_BUNDLE" ] || { echo "No CA bundle found" >&2; exit 1; }

cat > ~/.config/nix/nix.conf << EOF
store = ${NIX_USER_ROOT_STORE}
extra-experimental-features = flakes nix-command
ssl-cert-file = ${CA_BUNDLE}
extra-substituters = https://cache.astro-nix.space/
extra-trusted-public-keys = astro-nix-secret:QASg0gb6rH/PxxthSsoGvw739dyKwEIVnhhhD7wA02A=
ignored-acls = lustre.lov
EOF


```

4- Bootstrap basic packages and test it

```
# will take some time on first run
nix search nixpkgs hello
# install and run a first package
nix run nixpkgs#hello

```
