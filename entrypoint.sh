#!/bin/sh
set -ex

TS_FORMAT="%Y-%m-%dT%H:%M:%S%z "

if [ -e /etc/logrotate.conf ]; then
  echo "Using mounted /etc/logrotate.conf:" | ts "${TS_FORMAT}"
  cp /etc/logrotate.conf "$HOME/logrotate.conf"
else
  echo "Using templated /etc/logrotate.conf:" | ts "${TS_FORMAT}"
  {
    echo "/logs/${LOGROTATE_FILE_PATTERN:-*.log} {"
    echo "  ${LOGROTATE_TRUNCATE:-copytruncate}"
    echo "  ${LOGROTATE_COMPRESS:-nocompress}"
    echo "  rotate ${LOGROTATE_ROTATE:-7}"
    echo "  size ${LOGROTATE_SIZE:-50M}"
    echo "  copytruncate"
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

# Setup crontab
echo "${LOGROTATE_CRON:-*/15 * * * *} /usr/sbin/logrotate -v -s $HOME/logrotate.status $HOME/logrotate.conf" > /var/spool/cron/crontabs/logrotate

# Start crond with default crontab directory
exec crond -d "${CROND_LOGLEVEL:-7}" -f 2>&1 | ts "${TS_FORMAT}"
