{
  pkgs,
  lib ? pkgs.lib,
  kernel,
  ...
}:
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "tablet-mode-kernel-module";
  version = "unstable-2024-12-30";

  src = pkgs.fetchFromGitHub {
    owner = "rhalkyard";
    repo = "minibook-dual-accelerometer";
    rev = "2bd40f507dd97707ebaa93b88c6b662bf5e5b801";
    hash = "sha256-WMPgr8SimfVAJ5o1ePNW0Yp4TjDhbmlT9aTiAWSC8+Y=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  preBuild = ''
    cd platform-driver
  '';

  installPhase = ''
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/misc
    cp chuwi-dual-accel.ko $out/lib/modules/${kernel.modDirVersion}/misc/
  '';

  passthru.kernelPatch = "${finalAttrs.src}/platform-driver/0001-platform-x86-support-for-out-of-tree-MDA6655-dual-ac.patch";

  meta = with lib; {
    description = "Kernel module for Chuwi MiniBook X dual accelerometer";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
})
