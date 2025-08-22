FROM scratch

COPY installroot /

ARG version
ENV imagename="fedora-riscv64"

# Setze das bootc-Label
LABEL org.opencontainers.image.name=${imagename} \
	org.opencontainers.image.version=${version} \
	org.opencontainers.image.vendor="Dirk Gottschalk" \
	org.opencontainers.image.description="Base image of Fedora for RISCV64."
