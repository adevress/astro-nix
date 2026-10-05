# Starlink PAL (Positional Astronomy Library), a dependency of cotter/fixmwams.
# It is not packaged in nixpkgs (the `pal` attribute was removed as broken),
# so it lives here.  Headers install to <prefix>/include/star/pal.h, which is
# what cotter's `find_path(LIBPAL_INCLUDE_DIR NAMES star/pal.h)` expects.
{
  lib,
  stdenv,
  fetchurl,
  liberfa,
}:

stdenv.mkDerivation rec {
  name = "pal";
  version = "0.9.7";

  src = fetchurl {
    url = "https://github.com/Starlink/pal/releases/download/v${version}/pal-${version}.tar.gz";
    sha256 = "sha256-cVGqBcLiRWOUyuIEP+uW5k13kob7MaJ/8R7D3WYCEoY=";
  };

  buildInputs = [ liberfa ];

  # Same invocation as upstream's Dockerfile (mwatelescope/cotter), plus an
  # explicit ERFA location so the SOFA-backed routines are linked against it
  # instead of silently building without ERFA.
  configureFlags = [
    "--without-starlink"
    "--with-erfa=${liberfa}"
  ];

  # glibc declares strlcpy() in <string.h> behind __USE_MISC, which sources
  # defining strict feature macros (_POSIX_C_SOURCE, ...) hide; that breaks
  # the HAVE_STRLCPY build path with an implicit-declaration error.
  # Backport: have autoconf AC_DEFINE _DEFAULT_SOURCE in config.h (included
  # before the libc headers) so the glibc strlcpy() declaration is visible
  # everywhere without touching the individual sources.
  patches = [ ./001-strlcpy-glibc-default-source.patch ];

  # The patch touches configure.ac, which would make make try to re-run the
  # (missing, Starlink-patched) aclocal/autoconf/autoheader rules.  Keep the
  # shipped generated files authoritative by making them newer.
  postPatch = ''
    touch aclocal.m4 configure config.h.in Makefile.in
  '';

  # Keep the .la file out of the closure; cotter links with find_library().
  postInstall = ''
    rm -f "$out"/lib/libpal.la
  '';

  meta = with lib; {
    description = "Positional Astronomy Library (C re-implementation of SLALIB)";
    homepage = "https://github.com/Starlink/pal";
    license = licenses.lgpl3Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
