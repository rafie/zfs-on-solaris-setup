#!/usr/bin/bash

. files/vars.conf

#------------------------------------------------------------------------------
echo Setting up networking

CHKNET=`ifconfig -a | grep vmxnet3`
if [ "$CHKNET" ]; then
	echo "VMWare VMXNET3 interface is already loaded and running. Skipping..."
fi

# echo Configuring static IP
# echo Configuring DHCP

#------------------------------------------------------------------------------
echo Changing hostname to $HOST

echo $HOST > /etc/nodename

#------------------------------------------------------------------------------
echo Setting up DNS and /etc/hosts

cp -f files/etc/resolv.conf /etc/resolv.conf

sed 's/myhost/'${HOST}'/g' /etc/hosts > test
mv test /etc/hosts
sed 's/mydomain.local/'${DOMAIN}'/g' /etc/hosts > test
mv test /etc/hosts
if ! grep 'nis.avaya.com' /etc/hosts > /dev/null ; then
	cat files/etc/hosts >> /etc/hosts
fi

#------------------------------------------------------------------------------
echo Setting up NTP

cp -f files/etc/ntp.conf /etc/inet/ntp.conf
ntpdate -u  135.64.19.82

#------------------------------------------------------------------------------
echo Setting up NIS

cp files/etc/defaultdomain /etc/
domainname `cat /etc/defaultdomain`

cp files/etc/yp.conf /etc/yp.conf
cp files/etc/nsswitch.conf /etc/nsswitch.conf
cp files/etc/auto.master /etc/auto.master

cp files/var/yp/securenets /var/yp/
cp -r files/var/yp/binding /var/yp/

if ! grep '+:::' /etc/passwd > /dev/null ; then
	cat files/etc/passwd >> /etc/passwd
fi

if ! grep '+:::' /etc/group > /dev/null ; then
	cat files/etc/group >> /etc/group
fi

svcadm disable svc:/network/location:default ; svcadm enable svc:/network/location:default
svcadm disable svc:/network/nis/client:default ; svcadm enable svc:/network/nis/client:default

#------------------------------------------------------------------------------
echo Setting up AD

cp -f files/etc/krb5.conf /etc/krb5/

sharectl set -p pdc=135.124.65.12 smb
sharectl set -p lmauth_level=4 smb

svcadm disable svc:/network/smb/server:default; svcadm enable -r svc:/network/smb/server:default

smbadm join -u rvadmin rnd.avaya.com

if [[ $? -ne 0 ]] ; then
	echo "Error Joining domain, halting script"
	exit 1
fi

if ! idmap list|grep global > /dev/null ; then
	idmap add winname:rvadmin@rnd.avaya.com unixuser:root
	idmap add winname:*@global.avaya.com unixuser:*
fi

#------------------------------------------------------------------------------
echo Creating pool

#------------------------------------------------------------------------------
echo Creating volume

#------------------------------------------------------------------------------
echo Configure NFS share

#------------------------------------------------------------------------------
echo Configure CIFS share

#------------------------------------------------------------------------------
echo Setting up volume permissions
