
# Caddy as Reverse Proxy

For an introduction to Caddy, see the web: https://caddyserver.com/docs/

## Service setup

### docker-compose.yml

#### Volumes

The Caddy Docker container uses two volumes: one for the **data** directory and one for the **config** directory.

According to https://caddyserver.com/docs/conventions the config directory does not need to be persisted, so it will stay as an **anonymous volume** and could be deleted without concerns (e.g. `docker-compose down -v`).

The **data directory however must not be treated as cache**.
That's why it is mounted as a **named volume** and marked as **external**. That way it is not possible to delete it accidentally (e.g. by executing docker-compose down -v). It also needs to be created manually in advance: `docker create volume proxy-caddydata`.

Instead of bind mounting the Caddyfile, we bind mount a directory instead, containing the Caddyfile. This is kind of a workaround for the case where you want to propagate changes in this file from host to container. Some editors (like vim) do not update files appropriately, instead they create a new file and copy it into the the place. However, this creates a new inode and effectively destroys the bind mount.

#### Network

This service will run on the named network `proxy-network`. Other services, which want to be accessible behind this reverse proxy need to join the same network (i.e. needs to be specified in the other service's docker-compose.yml files).

#### Ports

Obviously, we need to expose to the host machine all the ports at which we want our services to be accessible. Usually that would be at least 80 and 443.

### Caddyfile

The Caddyfile contains a site block for the `proxy` address (which is the hostname under which this service will be reachable within the Docker network). There we switch on the **ACME server** and the **internal CA**.

For every site (address/domain) the reverse proxy shall handle the Caddyfile needs to contain a corresponding site block. By specifying the site block, Caddy will take care of all the HTTPS stuff automatically (https://caddyserver.com/docs/automatic-https).

Within these site blocks there are directives which determine how to handle request for that site. Usually it will be the `reverse_proxy` directive, effectively forwarding the request to some backend service.

#### CA and ACME server (for internal/upstream TLS)

Caddy will run its own CA as well as an ACME server. Other (backend) services can request a certificate from this ACME server. That way we can have TLS even on the upstream connection between frontend (reverse proxy) and backend (the actual services).

The reverse proxy functionality of Caddy will connect to the backend over TLS if the upstream is specified accordingly (upstream host starting with `https://` or explicitly specified using `tls` subdirective).

##### Root CA trust on Backend

For the backend services to request a certificate from the ACME server running on the proxy, the backend services need to know and trust the root certificate of the internal CA.

That means, the frontend/proxy needs to be run at least once. During start of the proxy Caddy, the root certificate of the internal CA will be generated. It's usually stored at `/data/caddy/pki/authorities/local/root.crt`.

This certificate needs to be extracted from the frontend/proxy container (or its data volume, respectively). Then the backend services need to be provisioned with this certificate:

* either by bind mounting it (e.g. in docker-compose.yml) directly to a place where the backend service will look for trusted certificates (e.g. `/etc/ssl/certs/proxy_ca_root.crt`)
* or - if using Caddy on the backend side as well - by adding it anywhere into the container and specifying the location in the Caddyfile of the backend service (e.g. global `acme_ca_root` option, see Caddy docs)

##### Root CA trust on Frontend (reverse proxy)

Due to some issue(?), the root certificate of Caddy's internal CA is not added properly to the system's trust store. 
The result is, that when the reverse proxy initiates the TLS session with the backend service (which will present a certificate signed by the internal Root CA), the certificate is not considered as valid ("x509: certificate signed by unknown authority").

See here for more details: https://caddy.community/t/caddy-in-docker-container-does-not-trust-its-own-root-ca-certificate-automatically/13671

As a workaround, the CA root certificate needs to be specified explicitly within the reverse_proxy directive, using the `tls_trusted_ca_certs` option.

## Useful commands

Reload config while container is running

```
docker exec proxy caddy reload --config /etc/caddy/Caddyfile
```

(Optionally, you can include parameter `-d` to suppress outputs, e.g. when calling this command automatically from a script.)


## Docker netwworking tweaks

One of the typical problems with running web servers or reverse proxies inside Docker containers is to make the source IP address of the requests visible inside the container.

The default Docker networking type *bridge* does some NAT, so that from inside the container you will always see the Gateway IP address of the Docker network (i.e. the host's IP on the Docker network) as the source address, e.g. 172.18.0.1 or 192.168.144.1 or something similar.
This is caused by the so-called Docker "userland-proxy". It's exactly the one doing the NAT on bridged networks.

Long story short: You have to **switch of the userland-proxy so that source addresses don't get rewritten**.

You can do that by editing some Docker daemon properties. Just edit the file `/etc/docker/daemon.json` (or create it, because usually it does not exist yet) and add the following JSON property there:

```
{
     "userland-proxy": false
}
```

Then you just need to restart your Docker daemon: `sudo service docker restart`

And that's it. From now on your containers will see the actual source address. So for Caddy as a reverse proxy now also the typical headers like `X-Forwarded-For` will be set correctly.

You can find a more detailed blog post on that topic here: https://deavid.wordpress.com/2019/06/15/how-to-allow-docker-containers-to-see-the-source-ip-address/
