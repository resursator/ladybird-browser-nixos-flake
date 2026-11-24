{
  pkgs,
  lib ? pkgs.lib,
}:

let
  src = pkgs.fetchFromGitHub {
    owner = "LadybirdBrowser";
    repo = "ladybird";
    rev = "2026.47.7";
    hash = "sha256-ZSJ6QjGA7MAR/8joe0NwkhJyWZw/ag4tOCd0+F7siAA=";
  };
in
pkgs.callPackage ./ladybird-alpha-package.nix {
  inherit src;
}
