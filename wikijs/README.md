
# Wiki.js – Self-hosted Wiki

Wiki.js is simple, easy to use Wiki software based on Node.js. It has a lot of features like Enterprise Authentication (LDAP, OIDC, SAML, ...), Social Authentication (Google, Facebook, Github, Discord, Slack, ...), 2FA, many kinds of editors (Markdown, WYSIWIG, plain text) and many more.

https://js.wiki

It uses the Docker image from the Github repo: https://ghcr.io/requarks/wiki.
The compose file is adapted based on the instruction described in the official docs: https://docs.requarks.io/install/docker

## Service setup

### Adjust docker compose

Copy `wikijs-initial.sample.env` to `wikijs-initial.env`. Edit the database password. 
This value needs to be used only during the first startup.

Copy `wikijs.sample.env` to `wikijs.env`. Edit the file and adjust the database password to the actual value (as set in the other env file). The other environment variables usually don't need to be adapted.

### Volumes

The database volume is marked as external, so you have to create it in advance before the first startup:

```
docker volume create wikijs-pgdb
```

### Network and Reverse Proxy

The Wiki.js service is connected to the proxy network, which is the one defined by our Caddy proxy server.

In the reverse proxy Caddyfile, add an entry like this and adjust the domain to your needs:

```
wiki.domain.tld {
        reverse_proxy http://wikijs:3000
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

After the first startup, you can delete the `wikijs-initial.env` file, it's not required anymore since the database user has been created during first startup.
The file is set as optional because of the added `required: false` in the compose file, so the services will continue to startup properly, even if the referenced file is missing.
This feature was introduced with docker compose 2.24.0.
