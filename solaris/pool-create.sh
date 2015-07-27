#!/usr/bin/bash

#------------------------------------------------------------------------------
echo "Currently the pool is consisted of the following devices:"
echo "Pool Name:"
zpool status | /usr/xpg4/bin/grep -A 2 NAME | sed 1d

echo -e "\nThe following drives are available (showing without slice and without syspool first drive usage)\n"

iostat -xn | grep -v fd0 | grep -v hom | grep -v devic | grep -v c0t0| awk '/c/  {print $11}' | sed 1d

#------------------------------------------------------------------------------

echo -e "\nCreating pool name test which consist of disks & mirrors"

if ! zpool list | grep test > /dev/null; then
	echo "Creating..."
	zpool create test mirror c1t1d0 c1t2d0 mirror c1t3d0 c1t4d0 mirror c1t5d0 c1t6d0
else
	echo "Pool already created, skipping creation.."
fi

echo -e "Here is the status of the pool following by the mount points...\n"
zpool status test 
zfs list test

#------------------------------------------------------------------------------

echo -e "\nSetting attributes"
zfs set compression=on test

echo "create FS (folder) inside test pool"
zfs create -o mountpoint=/nfs -o sharenfs=on -o casesensitivity=mixed test/folder1

zfs set recordsize=128k test/folder1
zfs set compression=on  test/folder1

#------------------------------------------------------------------------------
# NFS share

#------------------------------------------------------------------------------
# Samba share

zfs set sharesmb=name=test_folder1 test/folder1

#------------------------------------------------------------------------------
# Folder ACLs
