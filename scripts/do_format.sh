#!/bin/bash


COMMAND="find . -type f | grep '\.nix$' | xargs -P 16 -I {}  nixfmt {}"

nix shell -f ./ nixfmt --command bash -c "${COMMAND}"
 
