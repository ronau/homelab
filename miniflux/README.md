
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

For the first startup, just run:

```
docker compose up -d
```

Check the logs to make sure the service has started properly:

```
docker compose logs -f
```

After the first startup, you can delete the `miniflux-initial.env` file, it's not required anymore since the database and admin user has been created during first startup.
The file is set as optional because of the added `required: false` in the compose file, so the services will continue to startup properly, even if the referenced file is missing.
This feature was introduced with docker compose 2.24.0.
