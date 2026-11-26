# pocketfft — header-only FFT library used by CyberEther.
#
# Upstream does not ship a build system: the whole library is
# `pocketfft_hdronly.h`. Install the header and a pkg-config file so Meson
# consumers can use `dependency('pocketfft')`.
{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pocketfft";
  version = "0-unstable-2023-02-13";

  src = fetchurl {
    name = "pocketfft-5fb931a048d4ed6e2be304bbfb608f655f3da6bf.tar.gz";
    url = "https://codeload.github.com/mreineck/pocketfft/tar.gz/5fb931a048d4ed6e2be304bbfb608f655f3da6bf";
    sha256 = "425d9b206d3719c1f733403fff1139b291d63676d3134e6a5ab86476cfc5db3b";
  };

  dontBuild = true;

  installPhase = ''
        runHook preInstall

        mkdir -p "$out/include" "$out/lib/pkgconfig"
        install -m644 pocketfft_hdronly.h "$out/include/"

        cat > "$out/lib/pkgconfig/pocketfft.pc" <<EOF
    prefix=$out
    includedir=$out/include

    Name: pocketfft
    Description: Header-only FFT library
    Version: ${finalAttrs.version}
    Cflags: -I$out/include
    EOF

        runHook postInstall
  '';

  meta = with lib; {
    description = "Header-only FFT library (pocketfft_hdronly.h)";
    homepage = "https://github.com/mreineck/pocketfft";
    license = licenses.bsd3;
    platforms = platforms.all;
    maintainers = with maintainers; [ ];
  };
})
