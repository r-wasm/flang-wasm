ARG BASE=ubuntu:22.04
FROM $BASE
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC
ARG EMSCRIPTEN_VERSION=3.1.37

# Install prerequisites
RUN apt-get update && \
    apt-get -y install --no-install-recommends build-essential ca-certificates \
        cmake git python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install emsdk
RUN git clone --depth=1 https://github.com/emscripten-core/emsdk.git /opt/emsdk
WORKDIR /opt/emsdk
RUN ./emsdk install "${EMSCRIPTEN_VERSION}" && \
    ./emsdk activate "${EMSCRIPTEN_VERSION}"

# Build and install webR's patched LLVM flang
RUN git clone --depth=1 https://github.com/r-wasm/webr.git /tmp/webr
RUN . "/opt/emsdk/emsdk_env.sh" && \
    cd /tmp/webr/tools/flang && \
    make && make install

# Copy LLVM flang binaries into /opt/flang
RUN mkdir /opt/flang && \
    mv /tmp/webr/host /opt/flang/host && \
    mv /tmp/webr/wasm /opt/flang/wasm && \
    rm /opt/flang/host/bin/emfc && \
    strip --strip-unneeded /opt/flang/host/bin/*

# Setup emfc helper script
RUN cp /tmp/webr/tools/flang/emfc.in /opt/flang/emfc && \
    sed -i 's|@BIN_PATH@|\/opt\/flang\/host\/bin|' /opt/flang/emfc && \
    chmod +x /opt/flang/emfc

# Cleanup
RUN . "/opt/emsdk/emsdk_env.sh" && emcc --clear-cache
RUN rm -rf /tmp/webr /opt/emsdk/downloads/*-wasm-binaries.tbz2

# Squash docker image layers
FROM $BASE
ENV DEBIAN_FRONTEND=noninteractive TZ=UTC
COPY --from=0 / /
SHELL ["/bin/bash", "-c"]

