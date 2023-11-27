# LLVM Flang for WebAssembly

This repository contains tools to build a patched version of [LLVM's](https://llvm.org) `flang-new` compiler that can be used to compile Fortran sources for WebAssembly. A pre-built Fortran runtime library is also built for WebAssembly using [Emscripten](https://emscripten.org).

## What's included

* A `Makefile` that downloads, builds and installs the `flang-new` compiler from a [patched LLVM](https://github.com/r-wasm/llvm-project) source. Use the `PREFIX` make variable to control the installation directory (default, `"."`). Once installed, the `$(PREFIX)/host/bin/` directory will contain `flang-new`. The `$(PREFIX)/wasm/` directory will contain a pre-built Fortran runtime library compiled for WebAssembly, for use with Emscripten.

* A `Dockerfile`, which can be used to build a Docker container with LLVM Flang and the WebAssembly Fortran runtime library installed under the directory `/opt/flang`.

* A Nix flake file, `flake.nix`, which can be used to build LLVM Flang and the WebAssembly Fortran runtime library as a Nix package.

## What is this project used for?

The `flang-new` compiler is used as part of the build process for [webR](https://webr.r-wasm.org) to compile Fortran sources for WebAssembly. Compiling LLVM takes a long time and is fairly resource intensive. By building LLVM independently with a Docker container and/or Nix package, the result is cached and improves the performance of webR's CI scripts.

### Do I need this package to build webR?

Downloading this project as a Docker container or Nix package can shorten the time needed to build webR, but it is not required. WebR will compile LLVM from source in the build tree if it is not provided with Fortran compiler tools.

### Can I use this project to build WebAssembly packages for webR?

No, this project does not contain a version of R configured for use with WebAssembly, which is required to build R packages. To build R packages, either build [webR](https://github.com/r-wasm/webr) from source, or use a [Docker image containing a fully pre-built version of webR](https://github.com/r-wasm/webr#building-with-docker).
