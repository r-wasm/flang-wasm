# LLVM Flang for webR

This docker image contains a patched version of LLVM's `flang` compiler suite. The included tools can be used to compile Fortran sources for WebAssembly. Also included is a pre-built Fortran runtime library, compiled for WebAssembly using Emscripten.

## What's included

The `/opt/flang/host/bin/` directory contains the LLVM compiler binaries, stripped of debug symbols.

The helper script `/opt/flang/emfc` is to Fortran what Emscripten's `emcc` is to C. It takes in Fortran sources and outputs object binaries, with an optional linking step using `wasm-ld`.

The `/opt/flang/wasm/` directory contains a pre-built Fortran runtime library, compiled for WebAssembly using Emscripten.

## What is this Docker image used for?

This image is used as part of the CI infrastructure for webR, implemented through GitHub Actions. Compiling LLVM takes a long time and requires heavier computational resources than provided by GitHub. By building LLVM independently in a Docker image, the result is cached and there is no need to rebuild LLVM every time a new commit is made to the webR repository.

## Do I need this image to build webR?

The tools in this image can be used to shorten the time needed to build webR, as in webR's GitHub Actions scripts, but it is not required. WebR will build LLVM from source if it cannot find the Fortran compiler tools in the build tree.

## Can I use this image to build WebAssembly packages for webR?

No, this image does not contain a version of R configured for use with WebAssembly, which is required to build R packages. Either build webR from source, or use a [Docker image containing a fully pre-built version of webR](https://github.com/r-wasm/webr#building-with-docker). This image is only useful for building webR itself.
