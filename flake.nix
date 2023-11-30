{
  description = "LLVM Flang for WebAssembly";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  };

  outputs = { self, nixpkgs }:
    let
      allSystems =
        [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      # Helper to provide system-specific attributes
      forAllSystems = f:
        nixpkgs.lib.genAttrs allSystems (system:
          f {
            pkgs = import nixpkgs { inherit system; };
            inherit system;

            flang-source = nixpkgs.legacyPackages.${system}.fetchgit {
              url = "https://github.com/r-wasm/llvm-project";
              # This is the tip of the flang-wasm branch.
              rev = "dc88038cde2f2b1224d821e21e24b922a882412b";
              hash = "sha256-yNSXOM97pk6bE68oLJMz/QqhMmFDZ7iv5WnXAf9f6R8=";
            };
          });

    in {
      packages = forAllSystems ({ pkgs, flang-source, ... }: {
        default = pkgs.stdenv.mkDerivation {
          name = "flang-wasm";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            cacert # Needed for git clone to work on https repos
            cmake
            emscripten
            git
            libxml2
            llvmPackages_16.bintools
            llvmPackages_16.clang
            ninja
            python3
            zlib
          ];

          # The automatic configuration by stdenv.mkDerivation tries to do some
          # cmake configuration, which causes the build to fail.
          dontConfigure = true;

          buildPhase = ''
            if [ ! -d $(pwd)/.emscripten_cache-${pkgs.emscripten.version} ]; then
              cp -R ${pkgs.emscripten}/share/emscripten/cache/ $(pwd)/.emscripten_cache-${pkgs.emscripten.version}
              chmod u+rwX -R $(pwd)/.emscripten_cache-${pkgs.emscripten.version}
            fi
            export EM_CACHE=$(pwd)/.emscripten_cache-${pkgs.emscripten.version}
            echo emscripten cache dir: $EM_CACHE

            CMAKE_BUILD_PARALLEL_LEVEL=$NIX_BUILD_CORES make \
              SOURCE=${flang-source} \
              PREFIX=$out \
              FLANG_WASM_CMAKE_VARS="-DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DLLVM_USE_LINKER=lld"
          '';

          installPhase = ''
            make SOURCE=${flang-source} PREFIX=$out install
          '';
        };
      });

      # Development environment output
      devShells = forAllSystems ({ pkgs, system, ... }: {
        default = pkgs.mkShell {

          # Get the nativeBuildInputs from packages.default
          inputsFrom = [ self.packages.${system}.default ];

          # Any additional Nix packages provided in the environment
          packages = with pkgs; [ ];

          # This is a workaround for nix emscripten cache directory not being
          # writable. Borrowed from:
          # https://discourse.nixos.org/t/improving-an-emscripten-yarn-dev-shell-flake/33045
          # Issue at https://github.com/NixOS/nixpkgs/issues/139943
          #
          # Also note that `nix develop` must be run in the top-level directory
          # of the project; otherwise this script will create the cache dir
          # inside of the current working dir. Currently there isn't a way to
          # the top-level dir from within this file, but there is an open issue
          # for it. After that issue is fixed and the fixed version of nix is in
          # widespread use, we'll be able to use
          # https://github.com/NixOS/nix/issues/8034
          shellHook = ''
            if [ ! -d $(pwd)/.emscripten_cache-${pkgs.emscripten.version} ]; then
              cp -R ${pkgs.emscripten}/share/emscripten/cache/ $(pwd)/.emscripten_cache-${pkgs.emscripten.version}
              chmod u+rwX -R $(pwd)/.emscripten_cache-${pkgs.emscripten.version}
            fi
            export EM_CACHE=$(pwd)/.emscripten_cache-${pkgs.emscripten.version}
            echo emscripten cache dir: $EM_CACHE
          '';
        };
      });
    };
}
