FROM scratch AS ctx
COPY build_files /

FROM quay.io/fedora/fedora-bootc:43 AS base

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN sudo podman pull ghcr.io/jianzcar/zena:stable

RUN bootc container lint
