#!/bin/bash

# all packages are installed as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

service squid stop
systemctl disable squid.service
apt remove -y --allow-change-held-packages --purge squid squid3 squidclient squid-cgi squid-common squid-langpack squid-purge
find / -name squid*
find / -name squid3*
rm -r /usr/share/squid-langpack/
rm -r /usr/share/squid3/
rm -r /usr/share/squid/
rm -r /usr/share/vim/vim74/syntax/squid.vim
rm -r /usr/share/sosreport/sos/plugins/squid.py
rm -r /usr/share/sosreport/sos/plugins/__pycache__/squid.cpython-35.pyc
rm -r /etc/systemd/system/squid.service.d
rm -r /run/squid
rm -r /var/cache/apt/archives/squid-langpack_20150704-1_all.deb

#clear screen
clear 

echo "Script By JohnFordTV"
echo "SQUID Successfully Removed from the system"
