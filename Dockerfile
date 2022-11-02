ARG SUBNET_ID=Tf1L1dJNUUPXWGH3C6dFgzHLxeV4tS99UW2K1tW5Lb2SQreQA
ARG SUBNET_NAME=fitfishoe
ARG VM_ID=n6ya7fQUwBcErBWs4PwVNaH3muhiavYGu9sKjsYRXvuMPWgRF
ARG BLOCKCHAIN_ID=2J5AZfDNqWtg9FAXGZkP4qVRUp3SD9XcQrYZz878BmZ7ybpCN5
# Changes to the minimum golang version must also be replicated in
# scripts/build_avalanche.sh
# scripts/local.Dockerfile
# Dockerfile (here)
# README.md
# go.mod
# ============= Compilation Stage ================
FROM golang:1.18.5-buster AS builder
ARG SUBNET_NAME
ARG SUBNET_ID
ARG VM_ID
ARG BLOCKCHAIN_ID
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

# build subnet-evm
RUN cd subnet-evm && scripts/build.sh build/$VM_ID


# ============= Cleanup Stage ================
FROM debian:11-slim AS execution
ARG SUBNET_NAME
ARG SUBNET_ID
ARG VM_ID
ARG BLOCKCHAIN_ID

RUN apt-get update
RUN apt-get install gettext-base

# Copy the executables into the container
COPY --from=builder /build/build /usr/local/lib/avalanchego
RUN ln -s /usr/local/lib/avalanchego/avalanchego /usr/local/bin/avalanchego
COPY --from=builder /build/subnet-evm/build/$VM_ID /usr/local/lib/avalanchego/plugins

ADD avalanchego-conf-templates templates
RUN mkdir -p /root/.avalanchego/configs/vms/
RUN cat templates/node.json | envsubst > /root/.avalanchego/config.json
RUN cat templates/aliases.json | envsubst > /root/.avalanchego/configs/vms/aliases.json

RUN mkdir -p /root/.avalanchego/configs/chains-relaxed/C
RUN cp templates/chains-c.json /root/.avalanchego/configs/chains-relaxed/C/config.json
RUN mkdir -p /root/.avalanchego/configs/chains-relaxed/$BLOCKCHAIN_ID
RUN cp templates/chains-subnet-relaxed.json /root/.avalanchego/configs/chains-relaxed/$BLOCKCHAIN_ID/config.json

RUN mkdir -p /root/.avalanchego/configs/chains-restricted/C
RUN cp templates/chains-c.json /root/.avalanchego/configs/chains-restricted/C/config.json
RUN mkdir -p /root/.avalanchego/configs/chains-restricted/$BLOCKCHAIN_ID
RUN cp templates/chains-subnet-restricted.json /root/.avalanchego/configs/chains-restricted/$BLOCKCHAIN_ID/config.json

EXPOSE 9650 9651
ENTRYPOINT ["avalanchego", "--vm-aliases-file=/root/.avalanchego/configs/vms/aliases.json"]
