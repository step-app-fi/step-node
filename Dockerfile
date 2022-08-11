# Changes to the minimum golang version must also be replicated in
# scripts/ansible/roles/golang_base/defaults/main.yml
# scripts/build_avalanche.sh
# scripts/local.Dockerfile
# Dockerfile (here)
# README.md
# go.mod
# ============= Compilation Stage ================
FROM golang:1.17.9-buster AS builder
RUN apt-get update && apt-get install -y --no-install-recommends bash=5.0-4 git=1:2.20.1-2+deb10u3 make=4.2.1-1.2 gcc=4:8.3.0-1 musl-dev=1.1.21-2 ca-certificates=20200601~deb10u2 linux-headers-amd64

WORKDIR /build
# Copy and download avalanche dependencies using go mod
COPY go.mod .
COPY go.sum .
RUN go mod download

# Copy the code into the container
COPY . .

# Build avalanchego and plugins
RUN ./scripts/build.sh


# ============= Cleanup Stage ================
FROM debian:11-slim AS execution

RUN apt-get update
RUN apt-get install gettext-base

# Copy the executables into the container
COPY --from=builder /build/build /usr/local/lib/avalanchego
RUN ln -s /usr/local/lib/avalanchego/avalanchego /usr/local/bin/avalanchego

COPY templates/chains-c.json /root/.avalanchego/configs/chains/C/config.json

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9650 9651
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
