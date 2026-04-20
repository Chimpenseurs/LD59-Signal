{
  description = "Flake for godot";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      # Development environment
      devShell = pkgs.mkShell {
        name = "godot4";
        nativeBuildInputs = [pkgs.godot_4 pkgs.python3 pkgs.git pkgs.zola];
      };

      packages.site = pkgs.stdenv.mkDerivation {
        name = "gh-page";
        src = ./site;
        nativeBuildInputs = [pkgs.python3 pkgs.zola ];
        buildPhase = ''
          # Get the game
          mkdir -p static/files/game/
          cp -r ${self.packages.${system}.default}/* static/files/game
          cp static/coi-serviceworker.js static/files/game

          # More info here: https://github.com/godotengine/godot-proposals/issues/6616#issuecomment-1513340085
          sed -i 's#\(		<script src="index.js"></script>\)#		<script src="coi-serviceworker.js"></script>\n\1#g' static/files/game/index.html

          # build the site
          zola build -o output
        '';
        installPhase = ''
          mkdir -p $out
          cp -r output/* $out
        '';
      };

      packages.default = pkgs.stdenv.mkDerivation rec {
        # Thank you, that saved me a lot of time !
        # https://github.com/jtojnar/nixpkgs/blob/c46689dd5bef6adbb0cb3ea935b02e57e1b242c4/pkgs/by-name/pi/pixelorama/package.nix#L8
        stdenv = pkgs.stdenv;

        godot_version_folder = pkgs.lib.replaceStrings ["-"] ["."] pkgs.godot_4.version;
        name = "godot-game";
        src = ./.;

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.godot_4
          pkgs.godot_4-export-templates
        ];

        runtimeDependencies = map pkgs.lib.getLib [
          pkgs.alsa-lib
          pkgs.libGL
          pkgs.libpulseaudio
          pkgs.xorg.libX11
          pkgs.xorg.libXcursor
          pkgs.xorg.libXext
          pkgs.xorg.libXi
          pkgs.xorg.libXrandr
          pkgs.udev
          pkgs.vulkan-loader
        ];

        buildPhase = ''
          runHook preBuild
          cd godot

          export HOME=$(mktemp -d)
          mkdir -p $HOME/.local/share/godot/export_templates

          ln -s "${pkgs.godot_4-export-templates}" "$HOME/.local/share/godot/export_templates/${godot_version_folder}"

          mkdir -p _build/
          godot4 --headless --export-release Web ./_build/index.html

          runHook postBuild
        '';

        installPhase = ''
          mkdir -p $out
          cp -r _build/* $out
        '';
      };

      # nix fmt .
      formatter = pkgs.alejandra;
    });
}
