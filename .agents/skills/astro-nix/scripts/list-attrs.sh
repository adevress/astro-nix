#!/usr/bin/env bash
# List top-level installables provided by astro-nix (default.nix attrs).
# Usage: ./scripts/list-attrs.sh [--json]
# Must run from the astro-nix repo root.
set -euo pipefail
if [[ "${1:-}" == "--json" ]]; then
  nix eval -f ./ --apply 'builtins.attrNames' --json | jq .
else
  nix eval -f ./ --apply 'builtins.attrNames' --json | jq -r '.[]' | sort
fi
