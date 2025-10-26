{
  description = "RGBMatrixEmulator - A PC emulator for Raspberry Pi LED matrices";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    RGBMatrixEmulator = {
      url = "github:ty-porter/RGBMatrixEmulator";
      flake = false;
    };

    godown.url = "github:badele/godown";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      RGBMatrixEmulator,
      godown,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Dépendances système nécessaires pour pygame et autres paquets
        systemDeps = with pkgs; [
          # Pour pygame
          SDL2
          SDL2_image
          SDL2_mixer
          SDL2_ttf
          libpng
          libjpeg
          portmidi
          portaudio
          freetype

          # Pour Pillow
          zlib
          libtiff
          libwebp
          lcms2

          # Outils de build
          pkg-config
          gcc
          stdenv.cc.cc.lib

          just
          godown.packages.${system}.default
          gifsicle
        ];

        # Paquets Python manquants dans nixpkgs (à installer via pip)
        missingPythonPackages = [
          "bdfparser<=2.2.0"
        ];

        pythonEnv = pkgs.python3.withPackages (
          ps: with ps; [
            # Dépendances du projet disponibles dans nixpkgs
            numpy
            pillow
            pygame
            tornado

            # Outils de développement
            pip
            setuptools
            wheel

            # Dépendances de test
            black
            parameterized
          ]
        );

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ pythonEnv ] ++ systemDeps;

          # Variables d'environnement pour les bibliothèques dynamiques
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath systemDeps;

          shellHook = ''
            echo "🚀 RGBMatrixEmulator development environment"
            echo "Python version: $(python --version)"
            echo ""

            # Configuration pour pygame - essayer différents drivers
            # Enlever SDL_VIDEODRIVER pour laisser SDL auto-détecter
            unset SDL_VIDEODRIVER

            # Supprimer l'avertissement AVX2 de pygame
            export PYGAME_HIDE_SUPPORT_PROMPT="1"

            # Préserver DISPLAY et WAYLAND_DISPLAY si déjà définis
            export DISPLAY="''${DISPLAY:-:0}"

            # S'assurer que les bibliothèques sont trouvées
            export LIBRARY_PATH="${pkgs.lib.makeLibraryPath systemDeps}"
            export C_INCLUDE_PATH="${pkgs.lib.makeSearchPathOutput "dev" "include" systemDeps}"
            export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" systemDeps}"

            # Créer un répertoire local pour les paquets pip manquants
            mkdir -p .nix-python-packages
            export PIP_PREFIX="$PWD/.nix-python-packages"
            export PYTHONPATH="$PIP_PREFIX/lib/python3.13/site-packages:$PYTHONPATH"
            export PATH="$PIP_PREFIX/bin:$PATH"

            # Installer RGBMatrixEmulator depuis GitHub si pas déjà fait
            if [ ! -f ".nix-python-packages/.package_installed" ]; then
              echo "📦 Installing RGBMatrixEmulator from GitHub..."
              pip install --prefix="$PIP_PREFIX" --no-warn-script-location ${RGBMatrixEmulator}
              touch .nix-python-packages/.package_installed
            fi

            # Installer uniquement les paquets Python manquants via pip
            MISSING_PACKAGES="${pkgs.lib.concatStringsSep " " missingPythonPackages}"
            if [ ! -f ".nix-python-packages/.packages_installed" ]; then
              echo "📦 Installing missing Python packages: $MISSING_PACKAGES"
              pip install --prefix="$PIP_PREFIX" --no-warn-script-location --ignore-installed $MISSING_PACKAGES
              touch .nix-python-packages/.packages_installed
            fi

            echo ""
            echo "Available commands:"
            echo ""
          '';
        };

        packages.default = pkgs.python3Packages.buildPythonPackage {
          pname = "RGBMatrixEmulator";
          version = "0.11.2";

          src = RGBMatrixEmulator;

          format = "pyproject";

          nativeBuildInputs =
            with pkgs.python3Packages;
            [
              pip
            ]
            ++ systemDeps;

          buildInputs = systemDeps;

          propagatedBuildInputs = with pkgs.python3Packages; [
            bdfparser
            numpy
            pillow
            pygame
            tornado
          ];

          meta = with pkgs.lib; {
            description = "A PC emulator for Raspberry Pi LED matrices driven by rpi-rgb-led-matrix";
            homepage = "https://github.com/ty-porter/RGBMatrixEmulator";
            license = licenses.mit;
            maintainers = [ ];
          };
        };
      }
    );
}
