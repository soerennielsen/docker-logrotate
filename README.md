
# logrotate

This is a docker container based on Alpine Linux with `logrotate`.

It is specifically designed for high secure environment and non-root execution and to be used in Kubernetes environments where you want to run a sidecar

It uses UID 1000 for a "logrotate" user. You can set GID to whatever your log file permissions are set to if needed.
 
## Configuration

Simply mount a directory with your logs into the container at `/logs` and optionally
configure some logrotation features with the following environment variables:

- `LOGROTATE_FILE_PATTERN` (default: `*.log`): File pattern within the `/logs` directory for logs
  to be rotated by `logrotate`
- `LOGROTATE_TRUNCATE` (default: `copytruncate`): Truncation behaviour of logrotate, use either
  `copytruncate` or `nocopytruncate`
- `LOGROTATE_COMPRESS` (default: `nocompress`): Compression behaviour for rotated files, use
  either `nocompress` or `compress`
- `LOGROTATE_ROTATE` (default: `7`): The `rotate` option of logrotate
- `LOGROTATE_SIZE` (default `50M`): the `size` option of logrotate
- `LOGROTATE_DAILY` (default `true`): enables daily rotation with date-based suffixes. When enabled,
  rotated files are named with date and time (e.g., `app.log-2025-01-06-1045`). When set to `false`,
  only size-based rotation is used with numeric suffixes (e.g., `app.log.1`)

If you want to use a different logrotate configuration, mount a `logrotate.conf` at `/etc/logrotate.conf`
into the container. The environment variables mentioned above have no effect if you supply your own
logrotate configuration file.

By default, `logrotate` is run periodically every 15 minutes. You can override the cron schedule with
the environment variable `LOGROTATE_CRON`. Use one of Alpine Linux' predefined periods
(`15min`, `hourly`, `daily`, `weekly` or `monthly`) or specify a cron schedule expression like
`5 4 * * *` (at 04:05 every day). If you are unsure about the cron schedule expression syntax,
consult a tool like [crontab guru](https://crontab.guru/).

## Examples

```bash
# Example 1: Size-based rotation with numeric suffixes
docker run \
  -v /path/to/my/logs:/logs \
  -e LOGROTATE_FILE_PATTERN="*.log" \
  -e LOGROTATE_DAILY="false" \
  -e LOGROTATE_SIZE="100M" \
  linkyard:logrotate

# Example 2: Daily rotation with size check
docker run \
  -v /path/to/my/logs:/logs \
  -e LOGROTATE_FILE_PATTERN="*.log" \
  # don't rotate at all but truncate logs when they exceed the configured rotation size
  -e LOGROTATE_ROTATE="0" \
  # run logrotate every 5 minutes
  -e LOGROTATE_CRON="*/5 0 0 0 0" \
  linkyard:logrotate
```

## Attribution

This image is similar to [linkyard/logrotate](https://github.com/linkyard/docker-logrotate)
but works in a non-root environment.


# Usage
`docker run ghcr.io/soerennielsen/logrotate`
