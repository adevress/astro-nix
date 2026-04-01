#!/bin/bash


nix shell -f ./ nixfmt --command find . -type f | grep "\.nix$" | xargs -P 16 -I {}  nixfmt {}
 
