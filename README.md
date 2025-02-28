
# logrotate

This is a docker container based on Alpine Linux with `logrotate`, specifically designed for:
- Non-root execution (runs as UID 1000 "logrotate" user)
- Kubernetes sidecar deployments
- High security environments
- Flexible log rotation with both time and size-based triggers

Uses [Supercronic](https://github.com/aptible/supercronic) for reliable non-root cron execution.

The container runs with user "logrotate" (UID 1000). You can set the GID to match your log file permissions if needed.
 
## Configuration

Simply mount a directory with your logs into the container at `/logs` and optionally
configure some logrotation features with the following environment variables:

- `LOGROTATE_FILE_PATTERN` (default: `*.log`): File pattern within the `/logs` directory for logs
  to be rotated by `logrotate`
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

## Notes

Running as non-root gives many "fun" scenarios. 

Set your GID to match the group of the log files you want to rotate, i.e. 
```yaml
  securityContext:
    runAsUser: 65532 
    runAsGroup: 65532
```

Note: These numbers should match the docker build, where you can use the args USER_UID (=65532) and USER_GID (=65532) to match your usecase. Default is suitable for Traefik logs.

In many cases "copytruncate" will fail in this scenario, so don't use that. 

Set the DEBUG flag to see what is happening and try to shell into the container and execute: 
```sh
/usr/sbin/logrotate -v -s $HOME/logrotate.status $HOME/logrotate.conf"
```

## Examples

```sh
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
```sh
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
          runAsUser: 65532
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
        ...

```

Note: Here I use a config map to provide a custom logrotate configuration. You can also just use the env variables.
