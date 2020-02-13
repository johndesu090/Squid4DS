#!/bin/bash

# all packages are installed as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#update
apt-get clean && apt-get update && apt-get upgrade -y && apt-get --fix-missing install -y && apt-get autoremove -y


# initializing var
OS=`uname -m`;
MYIP=$(curl -4 icanhazip.com)
if [ $MYIP = "" ]; then
   MYIP=`ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1`;
fi
MYIP2="s/xxxxxxxxx/$MYIP/g";


# install build tools
apt-get -y install \
    devscripts build-essential fakeroot \
    debhelper dh-autoreconf dh-apparmor cdbs ed net-tools

# install additional header packages for squid 4
apt-get -y install \
    libcppunit-dev \
    libsasl2-dev \
    libxml2-dev \
    libkrb5-dev \
    libdb-dev \
    libnetfilter-conntrack-dev \
    libexpat1-dev \
    libcap2-dev \
    libldap2-dev \
    libpam0g-dev \
    libgnutls28-dev \
    libssl-dev \
    libdbi-perl \
    libecap3 \
    libecap3-dev

# install build dependences for squid
apt-get -y build-dep squid

# set squid version
wget https://www.dropbox.com/s/45yzot67ipcqei9/squid.ver
source squid.ver

# decend into working directory
wget https://www.dropbox.com/s/e9ugenugoir3kbt/debian9_squid4.9.tar.gz
tar -xzvf debian9_squid4.9.tar.gz
pushd /root/root/build/

# get arch
ARCH="amd64"
cat /proc/cpuinfo | grep -m 1 ARMv7 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    ARCH="armhf"
fi

# install squid packages
apt-get install -y squid-langpack
dpkg --install squid-common_${SQUID_PKG}_all.deb
dpkg --install squid_${SQUID_PKG}_${ARCH}.deb
dpkg --install squidclient_${SQUID_PKG}_${ARCH}.deb

# and revert
popd

# put the squid on hold to prevent updating
apt-mark hold squid squidclient squid-common squid-langpack

# change the number of default file descriptors
OVERRIDE_DIR=/etc/systemd/system/squid.service.d
OVERRIDE_CNF=$OVERRIDE_DIR/override.conf

mkdir -p $OVERRIDE_DIR

# generate the override file
rm $OVERRIDE_CNF
echo "[Service]"         >> $OVERRIDE_CNF
echo "LimitNOFILE=65535" >> $OVERRIDE_CNF

# and reload the systemd
systemctl daemon-reload
systemctl enable squid

#setup squid.conf
mv /etc/squid/squid.conf /etc/squid/squid.conf.bak
cat > /etc/squid/squid.conf <<-END
http_port 8085
http_port 3355
acl localnet src 0.0.0.1-0.255.255.255  # RFC 1122 "this" network (LAN)
acl localnet src 10.0.0.0/8             # RFC 1918 local private network (LAN)
acl localnet src 100.64.0.0/10          # RFC 6598 shared address space (CGN)
acl localnet src 169.254.0.0/16         # RFC 3927 link-local (directly plugged) machines
acl localnet src 172.16.0.0/12          # RFC 1918 local private network (LAN)
acl localnet src 192.168.0.0/16         # RFC 1918 local private network (LAN)
acl localnet src fc00::/7               # RFC 4193 local private network range
acl localnet src fe80::/10              # RFC 4291 link-local (directly plugged) machines

acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 110         # openvpn
acl Safe_ports port 21          # ftp
acl Safe_ports port 442         # dropbear
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http

acl CONNECT method CONNECT
acl SSH dst xxxxxxxxx-xxxxxxxxx/255.255.255.255
http_access allow SSH

http_access allow localhost manager
http_access deny manager
http_access allow localnet
http_access allow localhost
http_access deny all

coredump_dir /squid/var/cache/squid

refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
visible_hostname JohnFordTV
END
sed -i $MYIP2 /etc/squid/squid.conf;
service squid restart

rm -R /root/root
rm -R /root/*.gz

#clear screen
clear 

echo " "
echo "INSTALLATION COMPLETE!"
echo "Please do a reboot first"
echo " "
echo "Squid ports : 8085, 3355"
echo "You may change the port via: nano /etc/squid/squid.conf , and then run command # service squid restart"
echo " "
echo "Thank You"
echo "Script Compiled by JohnFordTV"
echo "Credits to: https://docs.diladele.com/ for squid4 source"
