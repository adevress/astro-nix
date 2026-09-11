# CyberEther geodata bundle
#
# resources/geodata/*.geojson are NOT tracked in the CyberEther git repo
# (gitignored); parser.py downloads them at build time from
# https://cdn.cyberether.org/geodata/ (not available inside the Nix build
# sandbox). This package pins all 20 files (served from the same CDN,
# hashes verified against the project's native build cache) so the
# world-map/geodata feature builds fully offline.
{ runCommand, fetchurl }:

let
  files = [
    {
      name = "ne_10m_admin_0_boundary_lines_land.geojson";
      sha256 = "74d9c16229c095fde65943a9919e337682f044bcebccb120764f38edf3b70f4a";
    }
    {
      name = "ne_10m_admin_1_states_provinces_lines.geojson";
      sha256 = "1a1f30ccaaf4cc9c4bde34266f0b8cbb955d3a4cf254b756912255f2ec7c75b6";
    }
    {
      name = "ne_10m_bathymetry_A_10000.geojson";
      sha256 = "8821d6e8003f0a74a6d1d18379ded88ee638b3e457f2bab9d4124acc3cd15492";
    }
    {
      name = "ne_10m_bathymetry_B_9000.geojson";
      sha256 = "ff0e96b3c3baa863f82503fe3434bd604ffe6fbd27cabee7f71dd1807fcee5a0";
    }
    {
      name = "ne_10m_bathymetry_C_8000.geojson";
      sha256 = "8f3694037be7f54bf49fc6fa3f2045f325eacdb69c8828b8d482b303b57e358a";
    }
    {
      name = "ne_10m_bathymetry_D_7000.geojson";
      sha256 = "19eb5dd59d37d6c6da9b0d04252769c62708aad6a1578f16d6a7b8b30fd05c56";
    }
    {
      name = "ne_10m_bathymetry_E_6000.geojson";
      sha256 = "75fc34afdd5bc54a3ebe093fc0a680af70cf255f1b3e7e80ad75e795f5cc4c8d";
    }
    {
      name = "ne_10m_bathymetry_F_5000.geojson";
      sha256 = "e7b663f3f6144c1d23b8205618fd1eeb5256c4b03785a8ed009178209d68ba72";
    }
    {
      name = "ne_10m_bathymetry_G_4000.geojson";
      sha256 = "ad876e6b6b686494a0e89f0096880a6755aee77af3d738794bbbc92216afcf3d";
    }
    {
      name = "ne_10m_bathymetry_H_3000.geojson";
      sha256 = "28fda8b34dfb8615f9644bff3e56c184501e21dccb807d428432e56d8dac0cf5";
    }
    {
      name = "ne_10m_bathymetry_I_2000.geojson";
      sha256 = "cdedc746ce06e1a051cb8905e8f07855225ccbd3560ce3a66607651fc6953ce2";
    }
    {
      name = "ne_10m_bathymetry_J_1000.geojson";
      sha256 = "fa30219901dd4de34b9f5b20f41bc7c055f9fc9d58cf157ad2679c95239cd366";
    }
    {
      name = "ne_10m_bathymetry_K_200.geojson";
      sha256 = "5c6c182da8608153ea2dce22dfb32c987e5390e0bd4a122266143ba181a7b636";
    }
    {
      name = "ne_10m_bathymetry_L_0.geojson";
      sha256 = "e5efd9f47d56791c949de6d099d6a9cdd4d1aeca98d5dd63947c0b44b9966008";
    }
    {
      name = "ne_10m_coastline.geojson";
      sha256 = "6f75ae0e0de157b14946e2255eb1f5486d9a13819032e26d4610852d296788f6";
    }
    {
      name = "ne_10m_lakes.geojson";
      sha256 = "2d036f53dedec578001c5c30c2959ee7d4eebc1306900fa4367c49929ec8f2d9";
    }
    {
      name = "ne_10m_land.geojson";
      sha256 = "1ac90796408bc6ad6911d69448485d3c4dbf2190370080368a09976e1c9f7416";
    }
    {
      name = "ne_10m_populated_places_simple.geojson";
      sha256 = "fd3fa867a320cbd5c5b6bb5bc550afeec2939fb2cef688e508007282a55ac42f";
    }
    {
      name = "ne_10m_rivers_lake_centerlines.geojson";
      sha256 = "bb854a900ecbd3b408df46d5e16e3e0f974ba55993f9d8b5c26e855273c0905a";
    }
    {
      name = "ne_10m_urban_areas.geojson";
      sha256 = "5136ffd816a9b28c0f295e6797b4c03eaa421be80d78b90f542db4a932dd4497";
    }
  ];

  fetched = map (
    x:
    x
    // {
      src = fetchurl {
        name = x.name;
        url = "https://cdn.cyberether.org/geodata/${x.name}";
        sha256 = x.sha256;
      };
    }
  ) files;
in
runCommand "cyberether-geodata" { } ''
  mkdir -p $out/resources/geodata
  ${builtins.concatStringsSep "\n" (
    map (x: "ln -s ${x.src} \"$out/resources/geodata/${x.name}\"") fetched
  )}
''
