# docker build --no-cache -t mysticstorage.local:8443/library/notebook:lab-4.0.2 -f notebook.dockerfile .

# --- --- --- --- --- --- --- --- ---
# deno builder image.
#
FROM rust:1.75.0-bookworm AS builder

ENV CARGO_TARGET_DIR=/root/target

WORKDIR /root
RUN set -eux ;\
      apt update && apt install -y \
        cmake \
        protobuf-compiler \
        libssl-dev \
        pkg-config \
        build-essential \
      ;\
      # --- --- --- --- --- --- --- --- ---
      # build deno for TypeScript runtime.
      # --- --- --- --- --- --- --- --- ---
      cargo install deno@1.41.3 --locked

# --- --- --- --- --- --- --- --- ---
# notebook image.
#
FROM debian:bookworm-20240311-slim

ENV DEBIAN_FRONTEND=noninteractive

ENV http_proxy=
ENV https_proxy=
ENV no_proxy=

USER root
WORKDIR /root
RUN set -eux ;\
      # proxy config for apt
      echo "Acquire::http::Proxy \"$http_proxy\";" >>apt-proxy.conf ;\
      echo "Acquire::https::Proxy \"$https_proxy\";" >>apt-proxy.conf ;\
      mkdir -p /etc/apt/apt.conf.d ;\
      mv apt-proxy.conf /etc/apt/apt.conf.d/apt-proxy.conf ;\
      apt update && apt install -y \
        sudo \
      ;\
      # add a user for notebook.
      useradd -m -s /usr/bin/bash jovyan ;\
      # add jovyan to sudoers.
      echo 'jovyan ALL=(ALL:ALL) NOPASSWD:ALL' >> jovyan ;\
      mkdir -p /etc/sudoers.d ;\
      mv jovyan /etc/sudoers.d

ENV PATH=$PATH:/home/jovyan/.local/bin

USER jovyan
WORKDIR /home/jovyan
RUN set -eux ;\
      # --- --- --- --- --- --- --- --- ---
      # install Jupyter.
      # --- --- --- --- --- --- --- --- ---
      sudo apt update && sudo apt install -y \
        python3 \
        python3-pip \
      ;\
      pip install --break-system-packages --upgrade pip ;\
      pip install --break-system-packages \
        jupyterlab==4.0.2 \
        jupyterhub==4.0.2

ARG TARGETARCH
ENV GO_VERSION=go1.21.5
ENV PATH=$PATH:/usr/local/go/bin:/home/jovyan/go/bin

RUN set -eux ;\
      sudo apt update && sudo apt install -y \
        wget \
      ;\
      # --- --- --- --- --- --- --- --- ---
      # install Go.
      # --- --- --- --- --- --- --- --- ---
      wget https://go.dev/dl/${GO_VERSION}.linux-${TARGETARCH}.tar.gz ;\
      sudo tar -C /usr/local -xzf ${GO_VERSION}.linux-${TARGETARCH}.tar.gz ;\
      rm ${GO_VERSION}.linux-${TARGETARCH}.tar.gz ;\
      # --- --- --- --- --- --- --- --- ---
      # install Go Kernel.
      # --- --- --- --- --- --- --- --- ---
      go install github.com/janpfeifer/gonb@latest ;\
      go install golang.org/x/tools/cmd/goimports@latest ;\
      go install golang.org/x/tools/gopls@latest ;\
      gonb --install

RUN set -eux ;\
      sudo apt update && sudo apt install -y \
        curl \
      ;\
      # --- --- --- --- --- --- --- --- ---
      # install Rust and Rust Kernel.
      # --- --- --- --- --- --- --- --- ---
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y ;\
      . /home/jovyan/.cargo/env ;\
      cargo install evcxr_jupyter ;\
      evcxr_jupyter --install

COPY --from=builder /usr/local/cargo/bin/deno /usr/local/bin/deno
RUN set -eux ;\
      # --- --- --- --- --- --- --- --- ---
      # install Deno Kernel for TypeScript.
      # --- --- --- --- --- --- --- --- ---
      deno jupyter --install
