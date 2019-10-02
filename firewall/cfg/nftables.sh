#!/bin/sh -eu
# SUMMARY: simple stateful firewall
# REF: https://wiki.archlinux.org/index.php/Nftables

# Flush the current ruleset:
nft flush ruleset

# Add a table:
nft add table inet filter

# Add the input, forward, and output base chains. The policy for input and forward will be to drop. The policy for output will be to accept.
nft add chain inet filter input '{ type filter hook input priority 0 ; policy drop ; }'
nft add chain inet filter forward '{ type filter hook forward priority 0 ; policy drop ; }'
nft add chain inet filter output '{ type filter hook output priority 0 ; policy accept ; }'

# Add two regular chains that will be associated with tcp and udp:
nft add chain inet filter TCP
nft add chain inet filter UDP

# Related and established traffic will be accepted:
nft add rule inet filter input ct state related,established accept

# All loopback interface traffic will be accepted:
nft add rule inet filter input iif lo accept

# Drop any invalid traffic:
nft add rule inet filter input ct state invalid drop

# Accept ICMP and IGMP:
nft add rule inet filter input ip6 nexthdr icmpv6 icmpv6 type '{ destination-unreachable, packet-too-big, time-exceeded, parameter-problem, mld-listener-query, mld-listener-report, mld-listener-reduction, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, ind-neighbor-solicit, ind-neighbor-advert, mld2-listener-report }' accept
nft add rule inet filter input ip protocol icmp icmp type '{ destination-unreachable, router-solicitation, router-advertisement, time-exceeded, parameter-problem }' accept
nft add rule inet filter input ip protocol igmp accept

# New udp traffic will jump to the UDP chain:
nft add rule inet filter input ip protocol udp ct state new jump UDP

# New tcp traffic will jump to the TCP chain:
nft add rule inet filter input 'ip protocol tcp tcp flags & (fin|syn|rst|ack) == syn ct state new jump TCP'

# Reject all traffic that was not processed by other rules:
nft add rule inet filter input ip protocol udp reject
nft add rule inet filter input ip protocol tcp reject with tcp reset
nft add rule inet filter input counter reject with icmp type prot-unreachable

# At this point you should decide what ports you want to open to incoming connections, which are handled by the TCP and UDP chains. For example to open connections for a web server add:
nft add rule inet filter TCP tcp dport 80 accept

# To accept HTTPS connections for a webserver on port 443:
nft add rule inet filter TCP tcp dport 443 accept

# To accept SSH traffic on port 22:
nft add rule inet filter TCP tcp dport 22 accept

# To accept incoming DNS requests:
nft add rule inet filter TCP tcp dport 53 accept
nft add rule inet filter UDP udp dport 53 accept
