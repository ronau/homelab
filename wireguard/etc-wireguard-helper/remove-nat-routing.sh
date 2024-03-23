#!/bin/bash

# IPT="/sbin/iptables"
# IPT6="/sbin/ip6tables"          
 
WAN_IF="eth0"                    # NIC connected to the internet
WG_IF="wg0"                      # WG NIC 
WG_PORT="51820"                  # WG udp port

SUB_NET="10.0.100.0/24"            # WG IPv4 sub/net aka CIDR
SUB_NET_6="fd00:c0f:fee:100::/112"  # WG IPv6 sub/net
 
## IPv4 ##
iptables -t nat -D POSTROUTING -s $SUB_NET -o $WAN_IF -j MASQUERADE
iptables -D INPUT -i $WG_IF -j ACCEPT
iptables -D FORWARD -i $WAN_IF -o $WG_IF -j ACCEPT
iptables -D FORWARD -i $WG_IF -o $WAN_IF -j ACCEPT
iptables -D INPUT -i $WAN_IF -p udp --dport $WG_PORT -j ACCEPT
 
## IPv6 ##
ip6tables -t nat -D POSTROUTING -s $SUB_NET_6 -o $WAN_IF -j MASQUERADE
ip6tables -D INPUT -i $WG_IF -j ACCEPT
ip6tables -D FORWARD -i $WAN_IF -o $WG_IF -j ACCEPT
ip6tables -D FORWARD -i $WG_IF -o $WAN_IF -j ACCEPT
ip6tables -D INPUT -i $WAN_IF -p udp --dport $WG_PORT -j ACCEPT
