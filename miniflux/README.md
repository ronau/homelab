
# Miniflux self-hosted RSS reader

## Service setup

Credits to https://lukesingham.com/rss-feed-reader/

### Configure DB, usernames and passwords

Copy `miniflux-initial.sample.env` to `miniflux-initial.env`. Edit the copy and set usernames and passwords. 
These values will be used only during the first startup.

Copy `miniflux.sample.env` to `miniflux.env`. Edit the file and adjust the database connection string according to your actual database user and password (as set in the other env file):

```
DATABASE_URL=postgres://miniflux:secret@postgres/miniflux?sslmode=disable
```

Feel free to add additional environment variables according to your needs. They are described here: https://miniflux.app/docs/configuration.html

All these values will be used during every startup.

### Startup

For the first startup, refer to the environment file containing initial passwords etc.:
```
docker compose --env-file miniflux-initial.env up -d
```

For subsequent startups you don't need to point to this file anymore, just the simple:

```
docker compose up -d
```

The `miniflux.env` file is referred in the docker-compose.yml and will be used during every startup.

For security reasons you can now delete the `miniflux-initial.env`.
