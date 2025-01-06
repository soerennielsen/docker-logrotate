
# logrotate

This is a docker container based on Alpine Linux with `logrotate`, specifically designed for:
- Non-root execution (runs as UID 1000 "logrotate" user)
- Kubernetes sidecar deployments
- High security environments
- Flexible log rotation with both time and size-based triggers

The container runs with user "logrotate" (UID 1000). You can set the GID to match your log file permissions if needed.
 
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
- `DEBUG` (default `false`): enables debug output with command tracing
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
  ghcr.io/soerennielsen/logrotate

# Example 2: Daily rotation with size check
docker run \
  -v /path/to/my/logs:/logs \
  -e LOGROTATE_FILE_PATTERN="*.log" \
  # don't rotate at all but truncate logs when they exceed the configured rotation size
  -e LOGROTATE_ROTATE="0" \
  # run logrotate every 5 minutes
  -e LOGROTATE_CRON="*/5 0 0 0 0" \
  ghcr.io/soerennielsen/logrotate
```

## Attribution

This image is similar to [linkyard/logrotate](https://github.com/linkyard/docker-logrotate)
but works in a non-root environment.

## Usage

For Docker:
```bash
docker run ghcr.io/soerennielsen/logrotate
```

For Kubernetes, add as a sidecar container:
```yaml
traefik:
  deployment:
    replicas: 5
    podAnnotations:
      co.elastic.hints/package: traefik
      co.elastic.hints/host: traefik-metrics.traefik:9100

    additionalContainers:
      - name: logrotate
        image: ghcr.io/soerennielsen/logrotate:latest
        securityContext:
          runAsUser: 1000
          runAsGroup: 65532
        volumeMounts:
          - name: data
            mountPath: /logs
            readOnly: false
          - name: logrotate-config
            mountPath: /etc/logrotate.conf
            subPath: traefik-logrotate.conf

      - name: logtail
        image: busybox
        args: [/bin/sh, -c, "tail -F /logs/traefik.log"]
        volumeMounts:
          - name: data
            mountPath: /logs
            readOnly: true

    additionalVolumes:
      - name: logrotate-config
        configMap:
          name: traefik-logrotate-config
      - name: data
        ...

```

Note: Here I use a config map to provide a custom logrotate configuration. You can also just use the env variables.