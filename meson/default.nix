# Meson >= 1.11 override.
#
# CyberEther requires meson >= 1.11.0, but the pinned nixpkgs-25.11 only
# ships meson 1.9.1. This recipe is the upstream nixpkgs meson recipe
# (pkgs/by-name/me/meson/package.nix) fetched verbatim, with `version`
# bumped to 1.12.0 (latest release as of 2026-08) and the same set of
# Nixpkgs patches vendored alongside (see `*.patch`). The generated
# derivation *overrides* `pkgs.meson` for every astro-nix consumer.
#
{
  lib,
  stdenv,
  fetchgit,
  installShellFiles,
  coreutils,
  pkg-config,
  python3,
  replaceVars,
  writeShellScriptBin,
  zlib,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "meson";
  version = "1.12.0";
  format = "setuptools";

  # Meson upstream tarballs (GitHub archive) are regenerated non-deterministically
  # across CDN edges (the gzip bytes differ), which makes pinned tarball hashes
  # fragile. Use fetchgit instead: git object content is immutable. The upstream
  # nixpkgs recipe uses fetchFromGitHub; this is the only deviation from it.
  src = fetchgit {
    url = "https://github.com/mesonbuild/meson";
    rev = "e66ad8c5f70891247a60a30e81aaa7d21eb26890";
    sha256 = "sha256-gbSGIVIVcgBWBQTYWsMC6CYNAyVVFUOdsThGIBo7fvc=";
  };

  patches = [
    # Nixpkgs cmake uses NIXPKGS_CMAKE_PREFIX_PATH for the search path
    ./000-nixpkgs-cmake-prefix-path.patch

    # In typical distributions, RPATH is only needed for internal libraries so
    # meson removes everything else. With Nix, the locations of libraries
    # are not as predictable, therefore we need to keep them in the RPATH.
    # At the moment we are keeping the paths starting with /nix/store.
    # https://github.com/NixOS/nixpkgs/issues/31222#issuecomment-365811634
    (replaceVars ./001-fix-rpath.patch {
      inherit (builtins) storeDir;
    })

    # When Meson removes build_rpath from DT_RUNPATH entry, it just writes
    # the shorter NUL-terminated new rpath over the old one to reduce
    # the risk of potentially breaking the ELF files.
    # But this can cause much bigger problem for Nix as it can produce
    # cut-in-half-by-\0 store path references.
    # Let's just clear the whole rpath and hope for the best.
    ./002-clear-old-rpath.patch

    # The Nixpkgs 001 patch above is best-effort: it only recognises store
    # paths that appear in NIX_LDFLAGS, while the ld-wrapper also injects
    # rpaths for libraries discovered from pkg-config/link arguments. Those
    # entries are classified as build-only by Meson and dropped at install
    # time (see the `build_rpath` case). Make the guarantee unconditional in
    # depfixer: never remove an old DT_RPATH/DT_RUNPATH entry that points
    # into the store, so installed binaries and libraries keep locating
    # their store dependencies (including dlopen()-only ones that are not
    # listed in DT_NEEDED).
    (replaceVars ./008-keep-nix-store-rpath.patch {
      inherit (builtins) storeDir;
    })

    # Meson is currently inspecting fewer variables than autoconf does, which
    # makes it harder for us to use setup hooks, etc.
    # https://github.com/mesonbuild/meson/pull/6827
    ./003-more-env-vars.patch

    # Unlike libtool, vanilla Meson does not pass any information about the path
    # library will be installed to to g-ir-scanner, breaking the GIR when path
    # other than ${!outputLib}/lib is used.
    # We patch Meson to add a --fallback-library-path argument with library
    # install_dir to g-ir-scanner.
    ./004-gir-fallback-path.patch

    # Patch out default boost search paths to avoid impure builds on
    # unsandboxed non-NixOS builds, see:
    # https://github.com/NixOS/nixpkgs/issues/86131#issuecomment-711451774
    ./005-boost-Do-not-add-system-paths-on-nix.patch

    # This edge case is explicitly part of meson but is wrong for nix
    ./007-freebsd-pkgconfig-path.patch
  ];

  postPatch =
    if python3.isPyPy then
      ''
        substituteInPlace mesonbuild/modules/python.py \
          --replace-fail "PythonExternalProgram('python3', mesonlib.python_command)" \
                         "PythonExternalProgram('${python3.meta.mainProgram}', mesonlib.python_command)"
        substituteInPlace mesonbuild/modules/python3.py \
          --replace-fail "state.environment.lookup_binary_entry(mesonlib.MachineChoice.HOST, 'python3')" \
                         "state.environment.lookup_binary_entry(mesonlib.MachineChoice.HOST, '${python3.meta.mainProgram}')"
        substituteInPlace "test cases"/*/*/*.py "test cases"/*/*/*/*.py \
          --replace-quiet '#!/usr/bin/env python3' '#!/usr/bin/env pypy3' \
          --replace-quiet '#! /usr/bin/env python3' '#!/usr/bin/env pypy3'
        chmod +x "test cases"/*/*/*.py "test cases"/*/*/*/*.py
      ''
    else
      null;

  nativeBuildInputs = [ installShellFiles ];

  # Upstream runs the full meson test-suite as checkPhase (nativeCheckInputs =
  # [ ninja pkg-config ], checkInputs = [ zlib ... ]). Skipped here to keep
  # the derivation lean; meson is a build tool, not a library.

  doCheck = false;

  postInstall = ''
    installShellCompletion --zsh data/shell-completions/zsh/_meson
    installShellCompletion --bash data/shell-completions/bash/meson
  '';

  postFixup = ''
    pushd $out/bin
    # undo shell wrapper as meson tools are called with python
    for i in *; do
      mv ".$i-wrapped" "$i"
    done
    popd

    # Do not propagate Python
    rm $out/nix-support/propagated-build-inputs

    substituteInPlace "$out/share/bash-completion/completions/meson" \
      --replace "python3 -c " "${python3.interpreter} -c "
  '';

  setupHook = ./setup-hook.sh;
  env.hostPlatform = stdenv.targetPlatform.system;

  meta = {
    homepage = "https://mesonbuild.com";
    description = "Open source, fast and friendly build system made in Python";
    mainProgram = "meson";
    longDescription = ''
      Meson is an open source build system meant to be both extremely fast, and,
      even more importantly, as user friendly as possible.

      The main design point of Meson is that every moment a developer spends
      writing or debugging build definitions is a second wasted. So is every
      second spent waiting for the build system to actually start compiling
      code.
    '';
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    inherit (python3.meta) platforms;
  };
}
