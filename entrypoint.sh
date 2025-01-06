#!/bin/sh
if [ "${DEBUG:-false}" = "true" ]; then
  set -ex
fi

TS_FORMAT="%Y-%m-%dT%H:%M:%S%z "

if [ -f /etc/logrotate.conf ]; then
  echo "Using mounted /etc/logrotate.conf:" | ts "${TS_FORMAT}"
  cp -f /etc/logrotate.conf "$HOME/logrotate.conf"
else
  echo "Using templated /etc/logrotate.conf:" | ts "${TS_FORMAT}"
  {
    echo "/logs/${LOGROTATE_FILE_PATTERN:-*.log} {"
    echo "  ${LOGROTATE_COMPRESS:-nocompress}"
    echo "  rotate ${LOGROTATE_ROTATE:-7}"
    echo "  size ${LOGROTATE_SIZE:-50M}"
    echo "  missingok"
    echo "  notifempty"
    if [ "${LOGROTATE_DAILY:-true}" = "true" ]; then
      echo "  daily"
      echo "  dateext"
      echo "  dateformat -%Y-%m-%d-%H%M"
    fi
    echo "}"
  } > "$HOME/logrotate.conf"
fi
ts "${TS_FORMAT}" < "$HOME/logrotate.conf"

# Setup crontab for Supercronic
echo "${LOGROTATE_CRON:-*/15 * * * *} /usr/sbin/logrotate -v -s $HOME/logrotate.status $HOME/logrotate.conf" > "$HOME/cron/logrotate.cron"

# Start Supercronic
echo "starting supercronic" | ts "${TS_FORMAT}"
if [ "${DEBUG:-false}" = "true" ]; then
  exec supercronic -debug "$HOME/cron/logrotate.cron" 2>&1 | ts "${TS_FORMAT}"  
else
  exec supercronic "$HOME/cron/logrotate.cron" 2>&1 | ts "${TS_FORMAT}"
fi
