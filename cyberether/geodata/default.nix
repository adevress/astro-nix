# CyberEther 2.0 geodata bundle
#
# resources/geodata/fetch.py downloads a precompiled map archive from
# https://cdn.cyberether.org/geodata/ and verifies it against the SHA-256
# recorded in resources/geodata/manifest.json. The build sandbox has no
# network, so this package pins that exact archive. The file name is the
# manifest checksum: fetch.py looks it up as
# `.cache/geodata/<sha256>.bin` before attempting a download.
{ fetchurl }:

fetchurl {
  name = "d4b613a015c961580dd4a030f7f5dec31330820334656010d767eaef6c049412.bin";
  url = "https://cdn.cyberether.org/geodata/00001.bin";
  sha256 = "d4b613a015c961580dd4a030f7f5dec31330820334656010d767eaef6c049412";
}
