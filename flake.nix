{
  description = "Bocchi Cursors";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-parts } @ inputs:

    let
      mkBocchi = { lib, stdenvNoCC }: stdenvNoCC.mkDerivation {
        pname = "bocchi-cursors";
        version = "1.0";

        src = ./.;

        outputs = [ "normal" "shadowBlack" "out" ];
        outputsToInstall = [ ];

        dontBuild = true;

        installPhase = ''
          runHook preInstall

          for output in $(getAllOutputNames); do
            if [ "$output" != "out" ]; then
              local outputDir="''${!output}"
              local iconsDir="$outputDir/share/icons"

              # Convert to lisp-case
              local variant=$(sed 's/\([A-Z]\)/-\1/g' <<< "$output")
              local variant=''${variant,,}

              mkdir -p "$iconsDir"
              cp -r "bocchi-$variant" "$iconsDir"
            fi
          done

          mkdir -p "$out"

          runHook postInstall
        '';

        meta = with lib; {
          description = "Bocchi Cursors";
          homepage = "https://github.com/Weathercold/Bocchi-Cursors";
          license = licenses.unfree;
          platforms = platforms.all;
        };
      };

      flakeModule = { withSystem, ... }: {
        flake.overlays = rec {
          default = bocchi-cursors;
          bocchi-cursors = final: prev:
            withSystem prev.stdenv.hostPlatform.system
              ({ config, ... }: { inherit (config.packages) bocchi-cursors; });
        };

        systems = [
          "x86_64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
          "aarch64-linux"
          "armv7l-linux"
        ];

        perSystem = { pkgs, system, ... }: {
          packages = rec {
            default = bocchi-cursors;
            bocchi-cursors = pkgs.callPackage mkBocchi { };
          };
        };
      };
    in

    flake-parts.lib.mkFlake { inherit inputs; } flakeModule;
}
