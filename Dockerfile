FROM alpine:latest
LABEL version="1.0"
LABEL description="Exports Traefik ACME certificates to file"

RUN \
  apk update && \
  apk add --no-cache \
      inotify-tools \
      util-linux \
      bash \
      openssl

ADD https://raw.githubusercontent.com/kereis/traefik-certs-dumper/develop/bin/dump.sh /usr/bin/dump
ADD https://raw.githubusercontent.com/kereis/traefik-certs-dumper/develop/bin/healthcheck.sh /usr/bin/healthcheck

RUN ["chmod", "+x", "/usr/bin/dump", "/usr/bin/healthcheck"]

HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD ["/usr/bin/healthcheck"]

COPY --from=ldez/traefik-certs-dumper:v2.7.0 /usr/bin/traefik-certs-dumper /usr/bin/traefik-certs-dumper

VOLUME ["/traefik"]
VOLUME ["/output"]

ENTRYPOINT ["/usr/bin/dump"]
