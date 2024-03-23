
# BookStack – Self-hosted Information Management Platform

BookStack is a simple, self-hosted, easy-to-use platform for organising and storing information.

https://www.bookstackapp

It uses the Docker image from https://github.com/solidnerd/docker-bookstack.
The compose file is adapted a little bit to my personal approach.

## Service setup

### Adjust docker compose

Copy `bookstack-initial.sample.env` to `bookstack-initial.env`. Edit the copy and set usernames and passwords. 
These values need to be used only during the first startup.

Copy `bookstack.sample.env` to `bookstack.env`. Edit the file and adjust the database connection parameters to the actual values (as set in the other env file).

Also, you need to set the `APP_URL` to the *real* URL you are using to reach the service, e.g. URL of your reverse proxy server.

The value `APP_KEY` needs to be exactly 32 characters.

### Volumes

The volumes are marked as external, so you have to create them in advance before the first startup:

```
docker volume create bookstack-mysql-data
docker volume create bookstack-uploads
docker volume create bookstack-storage-uploads
```

### Network and Reverse Proxy

The bookstack service is connected to the proxy network, which is the one defined by our Caddy proxy server.

In the reverse proxy Caddyfile, add an entry like this and adjust the domain to your needs:

```
bookstack.domain.tld {
        reverse_proxy http://bookstack:8080
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

After the first startup, you can delete the `bookstack-initial.env` file, especially to avoid leaking your MySQL root password.
The file is set as optional because of the added `required: false` in the compose file, so the services will continue to startup properly, even if the referenced file is missing.
This feature was introduced with docker compose 2.24.0.
