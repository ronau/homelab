
# Wireguard as Home VPN

## tl;dr

1. Copy `etc-sysctl-d/10-wireguard.conf` to `/etc/sysctl.d/`
    * This will make sure that port forwarding will be switched on for both IPv4 and IPv6
    * Assumes that eth0 is the WAN interface (i.e. Raspi is connected via Ethernet port)
2. As root user, create wireguard directory (if not exists already)
    ```
    $ sudo -i
    # mkdir -m 0700 /etc/wireguard/
    # cd /etc/wireguard/
    ```
3. As root user, create private key and public key. Can be done in a single command. Make sure that key files have correct permissions.
    ```
    /etc/wireguard# umask 077
    /etc/wireguard# wg genkey | tee private.key | wg pubkey > public.key
    ```
4. Copy `wg0.conf` to `/etc/wireguard`. Make sure that it has correct permissions and owner (root:root 600).
5. Edit `/etc/wireguard/wg0.conf`, insert server private key and insert client public keys (each in a separate `[Peer]` section).
6. Copy helper scripts in `etc-wireguard-helper/` to `/etc/wireguard/helper/`. Make sure they have correct permissions and owner (root:root 700, should be executable!).
7. Edit helper scripts in `/etc/wireguard/helper/` so that interface IDs and IP ranges fit your needs
8. Include Wireguard into startup system: `systemctl enable --now wg-quick@wg0` (Wireguard must not be running for this to work). Check with `systemctl status wg-quick@wg0`
9. Use `wg show` to check if clients have been connected recently

Android and iOS clients can import client configs via QR code. The QR code can be generated on the Terminal using `qrencode`:
```
qrencode -t ansiutf8 < Client.conf
```

## Main steps (theory)

1. Configure static IP4
2. Enable IP forwarding
    * For IPv4 this is pretty straightforward: https://linuxconfig.org/how-to-turn-on-off-ip-forwarding-in-linux
3. Configure wg interface
4. Configure iptables rules to make sure that traffic is forwarded
5. For IPv6 support:
    1. Make sure that `slaac hwaddr` is switched on (i.e. disable IPv6 privacy extensions)
    2. Enable IPv6 forwarding (check out the separate paragraph)
    3. Add ip6tables rules

### IP Forwarding with IPv6

By default, a linux host will listen to IPv6 router advertisements (RAs) and use this to configure a default route. This is known as SLAAC.

However, if you switch on IPv6 forwarding
```
net.ipv6.conf.all.forwarding = 1
```
then the linux host will not listen to RAs anymore and won't do and SLAAC.

**But* there is another setting for the RA property
```
net.ipv6.conf.eth0.accept_ra = 2
```
which will accept RAs even with forwarding enabled.

Find more on this here:

* https://strugglers.net/~andy/blog/2011/09/04/linux-ipv6-router-advertisements-and-forwarding/
* https://taczanowski.net/linux-box-as-an-ipv6-router-with-slaac-and-dhcpv6-pd/
* https://yinqingwang.wordpress.com/2016/11/28/ipv6-address-lost-when-forwarding-enabled/

These settings can be applied automatically upon system start.
For this, a sysctl config file can be created and put into /etc/sysctl.d/ directory. Check out the example file (ready-to-use) in this repo.


## Tutorials and manuals on the Internet

The following articles are the baseline for these works here. Some focus on the very basics and do not mention anything about firewall (iptables) configuration. Some focus on firewall settings and/or IPv6 support.

Official Wireguard docs:

* https://www.wireguard.com
* https://www.wireguard.com/#conceptual-overview
* https://www.wireguard.com/quickstart/


Man pages: 

* https://git.zx2c4.com/wireguard-tools/about/src/man/wg.8
* https://git.zx2c4.com/wireguard-tools/about/src/man/wg-quick.8


Tutorials:

* https://www.heise.de/ratgeber/Sichere-VPN-Verbindungen-mit-WireGuard-unter-Windows-Linux-und-Android-4308737.html
* https://www.cyberciti.biz/faq/ubuntu-20-04-set-up-wireguard-vpn-server/


Here some articles, which focus on IPv6 support and all the firewall stuff:

* https://www.cyberciti.biz/faq/how-to-set-up-wireguard-firewall-rules-in-linux/
* https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/4/html/security_guide/s1-firewall-ipt-fwd
* https://stanislas.blog/2019/01/how-to-setup-vpn-server-wireguard-nat-ipv6/
* https://www.hardill.me.uk/wordpress/2021/04/20/setting-up-wireguard-ipv6/
* https://meet-unix.org/2019-03-21-wireguard-vpn-server.html
