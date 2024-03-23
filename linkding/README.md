
# Linkding self-hosted bookmark manager

https://github.com/sissbruecker/linkding

## Service setup

### Configuration

Copy `linkding.env.sample` to `linkding.env`. Edit the copy as necessary, e.g. to configure a postgres database. By default, sqlite is used and this seems fine for me.

The `linkding.env` file is referenced in the docker-compose.yml and will be used during every startup.

### Network

In the docker-compose.yml, the container is attached to the *external* `proxy-network` network, which belongs to the Caddy reverse proxy of our homelab and must be up already before starting the linkding container.

Linkding runs on port 9090.

### User data

The "official" examples and instructions on Github suggest to bind mount a data directory on the host into the container.
However, I prefer to use a **named volume** in the docker-compose.yml instead and mark it as **external**. That way it is not possible to delete it accidentally (e.g. by executing docker-compose down -v).

For this to work, the volume needs to be created manually in advance: `docker create volume linkding-data`.

### Startup

Just run

```
docker compose up -d
```

### Initial user

(taken from the Github instructions)

For security reasons, the linkding Docker image does not provide an initial user, so you have to create one after setting up an installation. To do so, replace the credentials in the following command and run it:

```
docker compose exec linkding python manage.py createsuperuser --username=joe --email=joe@example.com
```

The command will prompt you for a secure password. After the command has completed you can start using the application by logging into the UI with your credentials.

Alternatively you can automatically create an initial superuser on startup using the `LD_SUPERUSER_NAME` option in the `linkding.env` file.
