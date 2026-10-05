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
