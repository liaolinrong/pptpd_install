#!/bin/bash

yum install -y perl ppp iptables pptpd 

mv /etc/ppp/options.pptpd /etc/ppp/options.pptpd.bak
cat >> /etc/ppp/options.pptpd <<-EOF
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
proxyarp
lock
nobsdcomp
novj
novjccomp
nologfd
idle 2592000
ms-dns 8.8.8.8
ms-dns 8.8.4.4
EOF

mv  /etc/ppp/chap-secrets /etc/ppp/chap-secrets.bak
cat >>  /etc/ppp/chap-secrets <<-EOF
# Secrets for authentication using CHAP
# client server secret IP addresses
liao      *    linrong    *
EOF

mv   /etc/pptpd.conf /etc/pptpd.conf.bak
cat >> /etc/pptpd.conf <<-EOF
option /etc/ppp/options.pptpd
logwtmp
localip 192.168.9.1
remoteip 192.168.9.11-30
EOF

sed -i "/net.ipv4.ip_forward/c net.ipv4.ip_forward = 1" /etc/sysctl.conf 
/sbin/sysctl -p

iptables -t nat -A POSTROUTING -o eth0 -s 192.168.9.0/24 -j MASQUERADE
iptables -I INPUT -p tcp --dport 1723 -j ACCEPT
iptables -I INPUT -p tcp --dport 47 -j ACCEPT
iptables -I INPUT -p gre -j ACCEPT
iptables -I INPUT -p UDP --dport 53 -j ACCEPT

iptables -I FORWARD -s 192.168.9.0/24 -o eth0 -j ACCEPT
iptables -I FORWARD -d 192.168.9.0/24 -i eth0 -j ACCEPT

/etc/init.d/iptables save
/sbin/service iptables restart

service pptpd restart
 
chkconfig pptpd on
chkconfig iptables on
