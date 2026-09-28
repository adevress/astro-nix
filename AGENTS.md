
# Packages usage and general rules

Read @README.md and use the instructions


# Packaging guidelines

- Always prefer to use recipes that are already provided upstream (nixpkgs) if you can
- If a recipe is shared between several packages, make it a separate recipe and do not bundle it
- Always prefer patch files to inline build and source-file edits
- Make your recipe compatible with parallel builds by default
- Always format your recipe
- If the recipe has a lot of dependencies, try to provide options to enable / disable them selectively. Agree on a basic feature set
- Recipes with CUDA support should also be usable without CUDA if possible

## Source pinning and versions

- Pin sources with an exact `rev` and `sha256`, never a floating branch or tag
- Bump versions via the `version = "..."` attribute only, so that `fetchFromGitHub { rev = "v${version}"; }` stays in sync

## Meta and hygiene

- Always fill `meta` with `description`, `homepage`, `license` and `maintainers`; required for `nix search` and downstream consumers
- Set `enableParallelBuilding = true`, but add a comment when a package is memory-hungry so CI tweaks are not a mystery

## Purity

- Never rely on `builtins.currentSystem`; pass `system` explicitly through `callPackage`
