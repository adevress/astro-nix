{ stdenv }:

stdenv.mkDerivation {
  name = "hello";
  src = ./.;
  buildPhase = ''
    ${stdenv.cc}/bin/gcc -o hello hello.c
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin
  '';
}
