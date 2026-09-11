# Local meson subproject shim for CyberEther's bundled SDR stack.
#
# soapyhackrf does `subproject('libhackrf').get_variable('libhackrf_dep')`.
# Instead of building the bundled hackrf copy, this shim forwards that
# variable to the upstream nixpkgs hackrf package (libhackrf) discovered
# via pkg-config.
project('libhackrf', 'c')

libhackrf_dep = dependency('libhackrf', required: true)
