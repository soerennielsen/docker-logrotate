FROM alpine:3.21

RUN set -x \
  && apk add --no-cache logrotate tini tzdata moreutils \
  && rm /etc/logrotate.conf && rm -r /etc/logrotate.d \
  && mv /etc/periodic/daily/logrotate /etc/.logrotate.cronjob \
  && adduser -D -u 1000 logrotate \
  && mkdir -p /var/spool/cron/crontabs \
  && touch /var/spool/cron/crontabs/logrotate \
  && chmod 600 /var/spool/cron/crontabs/logrotate \
  && chown logrotate:logrotate /var/spool/cron/crontabs/logrotate \
  && chmod 755 /var/spool/cron \
  && chmod 755 /var/spool/cron/crontabs \
  && rm -f /etc/crontabs/root


RUN mkdir -p /home/logrotate/cron && \
    chown -R logrotate:logrotate /home/logrotate

COPY entrypoint.sh /home/logrotate/entrypoint.sh
RUN tr -d '\r' < /home/logrotate/entrypoint.sh > /tmp/entrypoint.sh && \
    mv /tmp/entrypoint.sh /home/logrotate/entrypoint.sh && \
    chmod +x /home/logrotate/entrypoint.sh && \
    chown logrotate:logrotate /home/logrotate/entrypoint.sh

USER logrotate

VOLUME ["/logs"]

ENTRYPOINT ["tini", "-g", "--"]
CMD ["/home/logrotate/entrypoint.sh"]
