
# HedgeDoc – real-time collaborative markdown notes

https://hedgedoc.org

It uses the Docker image from this repo: https://quay.io/repository/hedgedoc/hedgedoc.
The compose file is adapted based on the instruction described in the official docs: https://docs.hedgedoc.org/setup/docker/

## Service setup

### Adjust docker compose

Copy `hedgedoc-initial.sample.env` to `hedgedoc-initial.env`. Edit the database password. 
This value needs to be used only during the first startup.

Copy `hedgedoc.sample.env` to `hedgedoc.env`. Edit the file and adjust the password in the database connection string to the actual value (as set in the other env file). Adapt the other environment variables to your need, especially `CMD_DOMAIN` must be set to the **external** domain you will use for accessing HedgeDoc. Consider checking the documentation for further config settings: https://docs.hedgedoc.org/configuration/

### Volumes

The volumes are marked as external, so you have to create them in advance before the first startup:

```
docker volume create hedgedoc-pgdb
docker volume create hedgedoc-uploads
```

### Network and Reverse Proxy

The HedgeDoc service is connected to the proxy network, which is the one defined by our Caddy proxy server.

In the reverse proxy Caddyfile, add an entry like this and adjust the domain to your needs:

```
doc.domain.tld {
        reverse_proxy http://hedgedoc:3000
}
```

### Startup

For the first startup, just run:

```
docker compose up -d
```

Check the logs to make sure the service has started properly:

```
docker compose logs -f
```

After the first startup, you can delete the `hedgedoc-initial.env` file, it's not required anymore since the database user has been created during first startup.
The file is set as optional because of the added `required: false` in the compose file, so the services will continue to startup properly, even if the referenced file is missing.
This feature was introduced with docker compose 2.24.0.
