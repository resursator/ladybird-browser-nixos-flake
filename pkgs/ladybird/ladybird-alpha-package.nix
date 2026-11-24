{
  pkgs,
  lib ? pkgs.lib,
  src,
}:

let
  cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-fYqoQxHodl7DJMfjp3S000CF8kFSD996LTH3dKg7Dtw=";
  };

  ffmpegLadybird = pkgs.callPackage ./ffmpeg-ladybird.nix {
    ladybirdSrc = src;
  };

  oldSkia = lib.findFirst
    (pkg: (pkg.pname or "") == "skia")
    null
    pkgs.ladybird.buildInputs;

  oldMimalloc = lib.findFirst
    (pkg: (pkg.pname or "") == "mimalloc")
    null
    pkgs.ladybird.buildInputs;

  skia = oldSkia.overrideAttrs (prev: {
    gnFlags = prev.gnFlags ++ [
      ''extra_cflags+=["-DSKCMS_DLL"]''
    ];
  });

  mimalloc = oldMimalloc.overrideAttrs (_: {
    version = "2.2.7";
    src = pkgs.fetchFromGitHub {
      owner = "microsoft";
      repo = "mimalloc";
      tag = "v2.2.7";
      hash = "sha256-z9qMOTcGkURblZChXDGfQ58hrql52lG6EE1NQmxxuj0=";
    };
  });

  llvmLibcHeaders = pkgs.callPackage ./llvm-libc-headers.nix { };
in
pkgs.ladybird.overrideAttrs (old: {
  pname = "ladybird";
  version = "2026.47.7";

  inherit src cargoDeps;

  buildInputs =
    (lib.filter (
      pkg:
      !builtins.elem (pkg.pname or "") [
        "skia"
        "mimalloc"
        "ffmpeg"
      ]
    ) old.buildInputs)
    ++ [
      skia
      mimalloc
      ffmpegLadybird
      llvmLibcHeaders

      pkgs.brotli
      pkgs.cpptrace
      pkgs.glib
      pkgs.harfbuzz
      pkgs.libdrm
      pkgs.libGL
      pkgs.libjpeg_turbo
      pkgs.libpng
      pkgs.libpsl
      pkgs.libxml2
      pkgs.libedit
      pkgs.libtommath
      pkgs.wuffs
      pkgs.sqlite
      pkgs.zlib
      pkgs.zmij

      pkgs.vulkan-headers
      pkgs.vulkan-loader
      pkgs.vulkan-memory-allocator

      pkgs.qt6Packages.qtpositioning
    ];

  nativeBuildInputs = old.nativeBuildInputs ++ [
    pkgs.glslang
  ];

  postPatch = ''
    # New Rust releases can deprecate APIs used by this snapshot.
    substituteInPlace Meta/CMake/rust_crate.cmake \
      --replace-fail \
        'set(RUSTC_TARGET_FLAGS -Dwarnings ' \
        'set(RUSTC_TARGET_FLAGS '

    # Require the exact ICU version.
    perl -0pi -e \
      's/find_package\(ICU 78\.[0-9]+ EXACT REQUIRED COMPONENTS data i18n uc\)/find_package(ICU ${pkgs.icu78.version} EXACT REQUIRED COMPONENTS data i18n uc)/ or die "ICU dependency not found\n"' \
      Meta/CMake/check_for_dependencies.cmake

    # Install PDF.js assets and Ladybird integration patch.
    cp -r ${pkgs.pdfjs}/share/pdf.js pdfjs
    chmod -R u+w pdfjs
    patch -d pdfjs -p1 \
      < Meta/CMake/vcpkg/overlay-ports/pdfjs/0001-ladybird-embed.patch

    # Don't set absolute paths in RPATH.
    substituteInPlace Meta/CMake/lagom_install_options.cmake \
      --replace-fail "\''${CMAKE_INSTALL_BINDIR}" "bin" \
      --replace-fail "\''${CMAKE_INSTALL_LIBDIR}" "lib"
  '';

  preConfigure = ''
    mkdir -p build/Caches
    cmakeFlagsArray+=("-DLADYBIRD_CACHE_DIR=$PWD/build/Caches")

    mkdir -p build/Caches/HSTSPreload
    cp ${pkgs.chromium-hsts-preload-list}/share/chromium-hsts-preload-list/transport_security_state_static.json \
      build/Caches/HSTSPreload/
  '';

  cmakeFlags = (lib.filter (
    flag: !(lib.hasPrefix "-DLADYBIRD_CACHE_DIR=" flag)
  ) old.cmakeFlags) ++ [
    (lib.cmakeBool "ENABLE_CI_BASELINE_CPU" true)
    "-DENABLE_NETWORK_DOWNLOADS=OFF"
  ];
})
