FROM alpine:3.21

# Supercronic for non-root cron jobs
ARG SUPERCRONIC_VERSION=v0.2.29

RUN set -x \
  && apk add --no-cache logrotate tini tzdata moreutils curl \
  && rm /etc/logrotate.conf && rm -r /etc/logrotate.d \
  && mv /etc/periodic/daily/logrotate /etc/.logrotate.cronjob \
  && adduser -D -u 1000 logrotate \
  # Install Supercronic
  && ARCH=$(uname -m) \
  && if [ "$ARCH" = "x86_64" ]; then \
       ARCH="amd64"; \
     elif [ "$ARCH" = "aarch64" ]; then \
       ARCH="arm64"; \
     fi \
  && curl -fsSL "https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-linux-${ARCH}" \
     -o /usr/local/bin/supercronic \
  && chmod +x /usr/local/bin/supercronic \
  # Setup directories
  && mkdir -p /home/logrotate/cron \
  && chown -R logrotate:logrotate /home/logrotate

COPY entrypoint.sh /home/logrotate/entrypoint.sh
RUN tr -d '\r' < /home/logrotate/entrypoint.sh > /tmp/entrypoint.sh && \
    mv /tmp/entrypoint.sh /home/logrotate/entrypoint.sh && \
    chmod +x /home/logrotate/entrypoint.sh && \
    chown logrotate:logrotate /home/logrotate/entrypoint.sh

USER logrotate

VOLUME ["/logs"]

ENTRYPOINT ["tini", "-g", "--"]
CMD ["/home/logrotate/entrypoint.sh"]
