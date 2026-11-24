{
  pkgs,
  lib ? pkgs.lib,
}:

let
  rev = "e54169423e7ee5d8b41c2f1b6f7a59000c901ee0";

  src = pkgs.fetchurl {
    url = "https://github.com/llvm/llvm-project/archive/${rev}.tar.gz";
    hash = "sha512-Srfx8sSaZhFIs4QUwW02AEZ/Q6KVqwODNYCY6yQ03Qwh6iAtolvNRm07jxs5dSfdd5P0pwJfeTiEkv7ikZR77Q==";
  };
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "llvm-libc-headers";
  version = rev;

  inherit src;

  nativeBuildInputs = [
    pkgs.gnutar
    pkgs.gzip
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/include/llvm-libc" "$TMPDIR/llvm-project"

    tar -xzf "$src" \
      -C "$TMPDIR/llvm-project" \
      "llvm-project-${rev}/libc/hdr" \
      "llvm-project-${rev}/libc/include" \
      "llvm-project-${rev}/libc/shared" \
      "llvm-project-${rev}/libc/src/__support" \
      "llvm-project-${rev}/libc/src/string/memory_utils"

    libc="$TMPDIR/llvm-project/llvm-project-${rev}/libc"

    for directory in hdr include shared src/__support src/string/memory_utils; do
      mkdir -p "$out/include/llvm-libc/$(dirname "$directory")"
      cp -a "$libc/$directory" "$out/include/llvm-libc/$directory"
    done

    runHook postInstall
  '';
}
