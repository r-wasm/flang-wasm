FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive TZ=Europe/London

RUN apt-get update && \
    apt-get -y install --no-install-recommends build-essential curl wget git \
        make cmake ca-certificates python3 quilt liblzma-dev libpcre2-dev \
        llvm clang gfortran libz-dev libbz2-dev libcurl4-openssl-dev && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN cd /opt && \
    git clone --depth=1 https://github.com/emscripten-core/emsdk.git && \
    cd emsdk && \
    ./emsdk install "3.1.14" && \
    ./emsdk activate "3.1.14"

RUN cd /opt/emsdk && \
    . "/opt/emsdk/emsdk_env.sh" && \
    cd /tmp && \
    git clone --depth=1 https://github.com/georgestagg/webR.git && \
    cd /tmp/webR/tools/flang && make

RUN cd /tmp/webR/tools/flang && make install

RUN mkdir /opt/flang && \
    mv /tmp/webR/host /opt/flang/host && \
    mv /tmp/webR/wasm /opt/flang/wasm && \
    mv /tmp/webR/tools/flang/emfc /opt/flang/emfc && \
    sed -i 's/\/tmp\/webR\/host\/bin/\/opt\/flang\/host\/bin/g' /opt/flang/emfc && \
    rm -rf /tmp/webR

WORKDIR /opt

SHELL ["/bin/bash", "-c"]

