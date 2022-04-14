# Dockerfile for jenkins/anchore integration demonstration
FROM registry.access.redhat.com/ubi8-minimal:latest
LABEL maintainer="pvn@novarese.net"
LABEL name="anchorectl-pipeline"
LABEL org.opencontainers.image.title="anchorectl-pipeline"
LABEL org.opencontainers.image.description="Simple image to test anchorectl with Anchore Enterprise."

RUN microdnf -y install curl
USER root
RUN date > /image_build_timestamp
ENTRYPOINT /bin/false
