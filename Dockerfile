# Dockerfile for anchorectl demonstration

# use alpine:latest for a smaller image, but it often won't have any published CVEs
FROM registry.access.redhat.com/ubi8-minimal:latest
LABEL maintainer="pvn@novarese.net"
LABEL name="anchorectl-pipeline"
LABEL org.opencontainers.image.title="anchorectl-pipeline"
LABEL org.opencontainers.image.description="Simple image to test anchorectl with Anchore Enterprise."

USER root 
# use date to force a unique build every time
RUN set -ex && \
    echo "-----BEGIN OPENSSH PRIVATE KEY-----" > /ssh_key && \
    date > /image_build_timestamp
ENTRYPOINT /bin/false
