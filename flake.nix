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
      inherit (nixpkgs.lib) mapAttrs' nameValuePair;
      inherit (builtins) attrNames;

      variants = {
        "normal" = "Normal";
        "shadowBlack" = "Shadow Black";
      };

      mkBocchi = { lib, stdenvNoCC }: stdenvNoCC.mkDerivation {
        pname = "bocchi-cursors";
        version = "1.0";

        src = ./.;

        outputs = [ "out" ] ++ (attrNames variants);
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
              cp -r "bocchi-cursors-$variant" "$iconsDir"
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

      mkHomeModule = variant: display: nameValuePair
        "bocchi-cursors-${variant}"
        ({ pkgs, ... }: {
          home.pointerCursor = {
            package = self.packages.${pkgs.system}.bocchi-cursors.${variant};
            name = "Bocchi Cursors - ${display}";
            size = 32;
            gtk.enable = true;
            x11.enable = true;
          };
        });

      flakeModule = { withSystem, ... }: {
        flake = {
          overlays = rec {
            default = bocchi-cursors;
            bocchi-cursors = final: prev:
              withSystem prev.stdenv.hostPlatform.system
                ({ config, ... }: { inherit (config.packages) bocchi-cursors; });
          };

          homeModules = rec {
            default = bocchi-cursors-normal;
            bocchi-cursors-normal = null;
          } // (mapAttrs' mkHomeModule variants);
        };

        systems = nixpkgs.lib.systems.flakeExposed;

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
