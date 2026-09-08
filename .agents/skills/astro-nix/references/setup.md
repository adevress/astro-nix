# Setup: Nix + astro-nix cache

## Daemon (root) install

```bash
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
sudo ./scripts/nix-command-edit.sh   # enables nix-command+flakes, adds cache
sudo systemctl restart nix-daemon
# new shell, then:
nix --version
grep -E "experimental-features|substituters|trusted-public-keys" /etc/nix/nix.conf
```

`scripts/nix-command-edit.sh` appends (values from `config/nix-cache.source`):

```
extra-experimental-features = nix-command flakes
extra-substituters  = https://cache.astro-nix.space/
extra-trusted-public-keys = astro-nix-secret:QASg0gb6rH/PxxthSsoGvw739dyKwEIVnhhhD7wA02A=
```

## Rootless / HPC (no root)

Full procedure in `doc/rootless-nix.md`. Summary:

```bash
mkdir -p ~/bin
curl -L https://hydra.nixos.org/job/nix/maintenance-2.34/buildStatic.nix-cli.$(uname -m)-linux/latest/download-by-type/file/binary-dist -o ~/bin/nix
ln -sf ~/bin/nix ~/bin/nix-{build,shell,env}; chmod 775 ~/bin/nix
export NIX_USER_ROOT_STORE=/path/to/fast-disk/nix-store  # avoid slow NFS
mkdir -p $NIX_USER_ROOT_STORE; setfacl -nb $NIX_USER_ROOT_STORE; chmod 755 $NIX_USER_ROOT_STORE; chmod g-s $NIX_USER_ROOT_STORE
mkdir -p ~/.config/nix
cat > ~/.config/nix/nix.conf <<EOF
store = $NIX_USER_ROOT_STORE
extra-experimental-features = flakes nix-command
ssl-cert-file = /etc/ssl/ca-bundle.pem
extra-substituters = https://cache.astro-nix.space/
extra-trusted-public-keys = astro-nix-secret:QASg0gb6rH/PxxthSsoGvw739dyKwEIVnhhhD7wA02A=
ignored-acls = lustre.lov
EOF
```

Tested on: Ubuntu Intel x86_64 (root), EPFL Kuma (RHEL AMD+Nvidia,
rootless), CSCS Daint + EPFL Manticore (Grace+Hopper aarch64, rootless).

## Binary cache notes

- Read-only use needs only the `extra-substituters` + `extra-trusted-public-keys` lines above.
- Push needs `~/.aws/credentials` + `~/.nix/keys/astro-nix.key` (GitHub
  secrets `AWS_*`, `NIX_SIGN_KEY`) — see `ci/ci_build.sh:setup_aws_credentials`, `setup_nix_sign_key`. Never create or commit these files as an agent.
- Store path: `s3://astro-nix?region=weur&endpoint=...r2.cloudflarestorage.com` (Cloudflare R2).
