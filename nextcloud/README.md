
# Nextcloud

## Service setup

### docker-compose.yml

Here Nextcloud is running based on four services: PHP-FPM running the Nextcloud app (aka PHP files), a webserver serving static files and redirecting PHP files to the PHP-FPM daemon, a MariaDB server, and finally a Redis cache (which will speed up Nextcloud a lot).

There are also Nextcloud Docker versions relying on Apache as webserver. However, I wanted to work with Caddy again, as I use it already as reverse proxy and two Caddy instances would integrate very well.

The **MariaDB** server is set up during the first startup. For this, copy `nextcloud-initial.sample.env` to `nextcloud-initial.env`. Edit the copy and set the MariaDB root password as well as username, password and database name for the Nextcloud database.

After the first startup, you can delete the `nextcloud-initial.env` file, it's not required anymore since the database and the users have successfully been created.
The file is set as optional because of the added `required: false` in the compose file, so the services will continue to startup properly, even if the referenced file is missing.
This feature was introduced with docker compose 2.24.0.

The `nextcloud:fpm-alpine` image contains PHP-FPM based on Alpine Linux and it also contains the Nextcloud application files.

The **web server** (Caddy) just needs access to the Nextcloud directory in order to be able to serve the static files. It's sufficient, though, to mount them read-only.
In addition you have to bind mount the Caddyfile as well as the root certificate of your own internal CA, which is running on the reverse proxy Caddy. That way, this Caddy will automatically acquire a certificate from the ACME server running on the proxy. So eventually the connection between proxy and backend web server will be transport encrypted, too. Obviously, the web server needs to join both the nextcloud network (default) as well as proxy network.

The **Redis** container is the easiest part. It just needs to sit in the default nextcloud network and it must be referenced in the environment variables of the nextcloud app container/service. That will configure Nextcloud to use Redis and that's it.

#### Network

All Nextcloud related containers sit in the compose-specific `default` network. In addition, the webserver must be able to reach the proxy and the app container must be able to reach the database server.

#### Ports

No ports need to be exposed to the host machine, since all the traffic will go through the reverse proxy.

#### Volumes

It's recommended to separate the different files of a Nextcloud. So we have separate named volumes for the **application files**, the **config** as well as the **user data**. All of these volumes are marked as **external**. That prevents from deleting them accidentally (e.g. by running `docker-compose down -v`). Naturally, they have to be created manually in advance then: e.g. `docker create volume nextcloud-appbase`

In addition we keep a named volume also for the data of the webserver (Caddy data). That way, the certificate will be kept across service restarts. However, it's not marked as external. So it will be deleted if you shutdown the service with the `-v` option (which is not a big problem, though, the certificate will simply be acquired from the ACME server on the proxy the next time the Nextcloud service will be started).

### Caddyfile

The Caddyfile contains the important directive `acme_ca`, which tells Caddy where to request certificates from. This is pointing to the ACME server running on the reverse proxy Caddy. Check out the README of the reverse proxy to find out more about TLS encryption between frontend (proxy) and backend service.

The rest of the config is taken from some examples on the web.

It's mainly about serving the `/var/www/html` directory, allowing WebDAV, redirecting DAV endpoints, preventing access to sensitive parts of the Nextcloud directory and handing down PHP requests to the Nextcloud app.

## Nextcloud Cronjobs

Nextcloud needs to do lots of background tasks in order to run properly.
For this you have multiple options in the Administrator settings (under "Basic Settings"). The recommended way is to use `Cron` here. It relies on the system cron service to periodically call the cron.php in Nextcloud's main application directory.

However, since we're running Nextcloud in a minimal container (Alpine Linux with just PHP-FPM) it does not come with cron. There are several options to solve that issue (e.g. installing cron into the container). Some of them are described here: https://www.projekt-rootserver.de/cron-events-in-docker-containern-zum-laufen-bringen/2019/09/

The easiest and pretty straightforward solution is to **use the cron service of the Docker host system**. The command to execute periodically would be:
```
docker exec -u www-data -d nextcloud-ncapp-1 /usr/local/bin/php -q -f /var/www/html/cron.php
```

Now the following needs to be added to the crontab of the root user (just run `crontab -e`), so the Nextcloud cron job will be executed inside the container every 5 minutes:

```
*/5  *  *  *  * /usr/bin/docker exec -u www-data -d nextcloud-ncapp-1 /usr/local/bin/php -q -f /var/www/html/cron.php > /dev/null 2>&1
```

## Updating Nextcloud

See https://hub.docker.com/_/nextcloud/:

Updating the Nextcloud container is done by pulling the new image, throwing away the old container and starting the new one.

**It is only possible to upgrade one major version at a time.**

Since all data is stored in volumes, nothing gets lost. The startup script will check for the version in your volume and the installed docker version. If it finds a mismatch, it automatically starts the upgrade process.

When using docker-compose your compose file takes care of your configuration, so you just have to run:

```
docker-compose pull
docker-compose up -d
```


## Additional tips and nice-to-know stuff

### Adding missing packages to Alpine image

Sometimes there are warning messages in the Admin section which relate to missing packages in the container, e.g. missing imagemagick support for SVG images.

It is not recommended to customize the docker image so that the missing package will be installed. Preferably, the image stays untouched and is used as provided from Docker Hub.

Instead it is easier to just install the missing package manually once after every Nextcloud startup (which happens only every now and then):

```
docker exec -it nextcloud-ncapp-1 /bin/sh -c 'apk update; apk add imagemagick-svg'
```


### Remove signup banner on publicly shared links

https://help.nextcloud.com/t/solved-how-to-remove-bottom-banner-on-shared-links-theming/168249
