#!/bin/bash

TMP_FILE_NIX="$(mktemp)"

grep -v "extra-experimental-features" /etc/nix/nix.conf > ${TMP_FILE_NIX}

mv /etc/nix/nix.conf /etc/nix/nix.conf.bak.${RANDOM}

echo "" >>  ${TMP_FILE_NIX}
echo "extra-experimental-features = nix-command flakes" >> ${TMP_FILE_NIX}

cp ${TMP_FILE_NIX} /etc/nix/nix.conf
chmod 755 /etc/nix/nix.conf 
rm ${TMP_FILE_NIX}

