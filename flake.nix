{
  description = "Unofficial Ladybird browser alpha build with custom FFmpeg and dependency patches";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          ladybird = pkgs.callPackage ./pkgs/ladybird { };
        in
        {
          inherit ladybird;
          default = ladybird;
        }
      );
    };
}
