# Local meson subproject shim for CyberEther's bundled SDR stack.
#
# libhackrf, librtlsdr, libairspy and limesuite all do
# `subproject('libusb').get_variable('libusb_dep')`. Instead of building the
# bundled libusb 1.0.26 copy, this shim forwards that variable to the upstream
# nixpkgs libusb (1.0.29) discovered via pkg-config.
project('libusb', 'c')

libusb_dep = dependency('libusb-1.0', required: true, static: false)
