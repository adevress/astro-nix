#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_FILE_NIX="$(mktemp)"



source "${ASTRO_NIX_CACHE_CONFIG_FILE:-"${SCRIPT_DIR}/../config/nix-cache.source"}"


grep -v "extra-experimental-features" /etc/nix/nix.conf > ${TMP_FILE_NIX}

mv /etc/nix/nix.conf /etc/nix/nix.conf.bak.${RANDOM}

echo "** Enable extended CLI support"

echo "" >>  ${TMP_FILE_NIX}
echo "extra-experimental-features = nix-command flakes" >> ${TMP_FILE_NIX}

echo "** Enable the Nix cache for Astro nix"


echo "extra-substituters  = ${ASTRO_NIX_CACHE}" >> ${TMP_FILE_NIX}
echo "extra-trusted-public-keys = ${ASTRO_NIX_PUB_KEY}" >> ${TMP_FILE_NIX}



cp ${TMP_FILE_NIX} /etc/nix/nix.conf
chmod 755 /etc/nix/nix.conf 
rm ${TMP_FILE_NIX}

