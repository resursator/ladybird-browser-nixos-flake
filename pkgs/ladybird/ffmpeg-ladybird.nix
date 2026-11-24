{
  pkgs,
  lib ? pkgs.lib,
  ladybirdSrc,
}:

let
  version = "9.0.2";

  src = pkgs.fetchFromGitHub {
    owner = "FFmpeg";
    repo = "FFmpeg";
    rev = "n${version}";
    hash = "sha512-tZ+eVh9c+9Z1sbXgpfF35tXm2qttW0lONvnMtzkYa6sZuirq9b+hAAV3CHcXSeBK+axRz0b7vSvV1b7qpyq+vA==";
  };

  patchDir = "${ladybirdSrc}/Meta/CMake/vcpkg/overlay-ports/ffmpeg";

  patches = map (name: "${patchDir}/${name}") [
    "0003-fix-windowsinclude.patch"
    "0004-dependencies.patch"
    "0005-fix-nasm.patch"
    "0007-fix-lib-naming.patch"
    "0013-define-WINVER.patch"
    "0024-fix-osx-host-c11.patch"
    "0040-ffmpeg-add-av_stream_get_first_dts-for-chromium.patch"
    "0045-use-prebuilt-bin2c.patch"
    "0046-fix-msvc-detection.patch"
    "0047-fix-msvc-utf8.patch"
    "0049-fix-twolame-pkgconfig.patch"
    "0050-fix-test-ld-absolute-lib-paths.patch"
    "0051-fix-msvc-undef-flags.patch"
    "0052-fix-disable-unstable-swscale-link.patch"
    "0100-ladybird-symbol-version-nodes.patch"
    "0101-vulkan-decode-dpb-distinct-no-drm-modifiers.patch"
    "0102-vulkan-av1-clear-unused-ref-frame-mvs.patch"
  ];
in
pkgs.ffmpeg.overrideAttrs (old: {
  pname = "ffmpeg-ladybird";
  inherit version src patches;

  outputs = [ "out" ];
  doCheck = false;

  configureFlags = [
    "--prefix=${placeholder "out"}"
    "--libdir=${placeholder "out"}/lib"
    "--incdir=${placeholder "out"}/include"
    "--enable-pic"
    "--enable-shared"
    "--disable-static"
    "--disable-doc"
    "--disable-debug"
    "--disable-autodetect"
    "--disable-network"
    "--disable-programs"
    "--disable-everything"
    "--disable-pixelutils"

    "--build-suffix=-ladybird"

    "--enable-avcodec"
    "--enable-avformat"
    "--enable-swresample"

    "--enable-decoder=vp8,vp9,libdav1d,theora,vorbis,opus,flac,mp3float,pcm_u8,pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le,pcm_alaw,pcm_mulaw"
    "--enable-parser=vp8,vp9,av1,mpegaudio"

    "--enable-libdav1d"
    "--enable-libopus"

    "--enable-vulkan"
    "--enable-libdrm"
    "--enable-hwaccel=vp9_vulkan,av1_vulkan"
    "--enable-decoder=av1"
  ];

  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
    pkgs.pkg-config
    pkgs.nasm
    pkgs.shaderc
  ];

  buildInputs = (old.buildInputs or [ ]) ++ [
    pkgs.dav1d
    pkgs.libopus
    pkgs.libdrm
    pkgs.vulkan-headers
    pkgs.vulkan-loader
  ];

  # FFmpeg's configure script uses glslc to compile Vulkan shaders.
  preConfigure = (old.preConfigure or "") + ''
    export PATH="${pkgs.shaderc}/bin:$PATH"
  '';

  postFixup = ''
    addDriverRunpath "$out/lib/libavcodec-ladybird.so"
    addDriverRunpath "$out/lib/libavutil-ladybird.so"

    patchelf "$out/lib/libavcodec-ladybird.so" \
      --add-needed libvulkan.so \
      --add-rpath "${lib.makeLibraryPath [ pkgs.vulkan-loader ]}"
  '';
})
