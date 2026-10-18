# Test data needed by the DP3 test suite.
#
# DP3 normally downloads the MWA MeasurementSet through a CMake
# ExternalProject at build time, and casacore's measures data comes from a
# daily-updated archive that is not reproducible.  Pinning both here keeps the
# downloads out of the build and makes them reusable by other packages.
{
  fetchurl,
  runCommand,
  writeText,
}:

rec {
  # MWA MeasurementSet used by the DDECal integration tests.
  mwaTestMs = fetchurl {
    url = "https://support.astron.nl/software/ci_data/EveryBeam/MWA-single-timeslot.tar.bz2";
    sha256 = "sha256-OcufZWWCyX9AOIPhvv5QdF2KhsTOTf7lXQh/Q3pG5dw=";
  };

  # Casacore measures data (ephemerides + geodetic), needed by the unit and
  # integration tests for celestial <-> terrestrial frame conversions.  The
  # daily-updated WSRT_Measures.ztar is not reproducible, so pin a dated
  # snapshot from the ASTRON archive.
  wsrtMeasures = runCommand "casacore-wsrt-measures-20260715" { } ''
    mkdir -p $out
    tar xf ${
      fetchurl {
        url = "https://iers.astron.nl/WSRT_Measures_20260715-160001.ztar";
        sha256 = "sha256-8WB63lzerLhJJqLrGLdUxQ/rL8rSVXokqD1ayQeWKtc=";
      }
    } -C $out
  '';

  # casacore reads this resource file to locate the measures data.
  casarc = writeText "casacore-measures.aipsrc" ''
    measures.directory: ${wsrtMeasures}
  '';
}
