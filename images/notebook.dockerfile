# docker build --no-cache -t mysticstorage.local:8443/library/notebook:lab-4.0.2 -f notebook.dockerfile .

# --- --- --- --- --- --- --- --- ---
# deno builder image.
#
FROM rust:1.75-bookworm AS builder

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
      # build deno for JavaScript and TypeScript Runtime.
      # --- --- --- --- --- --- --- --- ---
      export CARGO_TARGET_DIR=/root/target ;\
      cargo install deno --locked

# --- --- --- --- --- --- --- --- ---
# notebook image.
#
FROM python:3.12.2-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

ENV http_proxy=
ENV https_proxy=
ENV no_proxy=

USER root
RUN set -eux ;\
      # proxy config for apt
      echo "Acquire::http::Proxy \"$http_proxy\";" >>apt-proxy.conf ;\
      echo "Acquire::https::Proxy \"$https_proxy\";" >>apt-proxy.conf ;\
      mkdir -p /etc/apt/apt.conf.d ;\
      mv apt-proxy.conf /etc/apt/apt.conf.d/apt-proxy.conf ;\
      apt update && apt install -y \
        sudo \
      ;\
      # add user for jupyter.
      useradd -m -s /bin/bash -u 1000 -g 100 jovyan ;\
      # add jovyan to sudoers.
      echo 'jovyan ALL=(ALL:ALL) NOPASSWD:ALL' >> jovyan ;\
      mkdir -p /etc/sudoers.d ;\
      mv jovyan /etc/sudoers.d

USER jovyan
WORKDIR /home/jovyan
ENV PATH=/home/jovyan/.local/bin:$PATH
RUN set -eux ;\
      # --- --- --- --- --- --- --- --- ---
      # install Jupyter.
      # --- --- --- --- --- --- --- --- ---
      pip install --upgrade pip ;\
      pip install --no-warn-script-location \
        jupyterhub==4.0.2 \
        jupyterlab==4.0.2 \
      ;\
      mkdir -p /home/jovyan/work

ENV GO_VERSION=1.21.5
RUN set -eux ;\
      sudo apt update && sudo apt install -y \
        wget \
        curl \
        build-essential \
      ;\
      # --- --- --- --- --- --- --- --- ---
      # install Go.
      # --- --- --- --- --- --- --- --- ---
      wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz ;\
      sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz ;\
      rm go${GO_VERSION}.linux-amd64.tar.gz

RUN set -eux ;\
      # --- --- --- --- --- --- --- --- ---
      # install Rust and Rust Kernel.
      # --- --- --- --- --- --- --- --- ---
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y ;\
      . /home/jovyan/.cargo/env ;\
      cargo install evcxr_jupyter ;\
      evcxr_jupyter --install

ENV PATH=$PATH:/usr/local/go/bin:/home/jovyan/go/bin
RUN set -eux ;\
      # --- --- --- --- --- --- --- --- ---
      # install Go Kernel.
      # --- --- --- --- --- --- --- --- ---
      go install github.com/janpfeifer/gonb@latest ;\
      go install golang.org/x/tools/cmd/goimports@latest ;\
      go install golang.org/x/tools/gopls@latest ;\
      gonb --install

COPY --from=builder /usr/local/cargo/bin/deno /usr/local/bin/deno
RUN set -eux ;\
      # --- --- --- --- --- --- --- --- ---
      # install Deno Kernel for JavaScript and TypeScript.
      # --- --- --- --- --- --- --- --- ---
      deno jupyter --unstable --install
