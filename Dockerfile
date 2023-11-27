ARG BASE=ubuntu:22.04
FROM $BASE
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC
ARG EMSCRIPTEN_VERSION=3.1.45

# Install prerequisites for building LLVM, R, and webR wasm system libraries
RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    curl \
    gfortran \
    git \
    gnupg \
    gperf \
    libbz2-dev \
    libcurl4-openssl-dev \
    libglib2.0-dev-bin \
    liblzma-dev \
    libpcre2-dev \
    libssl-dev \
    libxml2-dev \
    libz-dev \
    lld \
    ninja-build \
    pkg-config \
    python3 \
    quilt \
    sqlite3 \
    tzdata \
    unzip \
    wget

# Install emsdk
RUN git clone --depth=1 https://github.com/emscripten-core/emsdk.git /opt/emsdk
WORKDIR /opt/emsdk
RUN ./emsdk install "${EMSCRIPTEN_VERSION}" && \
    ./emsdk activate "${EMSCRIPTEN_VERSION}"

# Build LLVM flang
COPY Makefile /root/flang-wasm/Makefile
RUN . "/opt/emsdk/emsdk_env.sh" && \
    cd "/root/flang-wasm" && \
    make PREFIX="/opt/flang" && \
    make PREFIX="/opt/flang" install

# Clean up
RUN . "/opt/emsdk/emsdk_env.sh" && emcc --clear-cache
RUN rm -rf "/root/flang-wasm" "/opt/emsdk/downloads/*-wasm-binaries.tbz2"
RUN apt-get clean && rm -rf "/var/lib/apt/lists/*"

# Squash docker image layers
FROM $BASE
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC
COPY --from=0 / /
SHELL ["/bin/bash", "-c"]

