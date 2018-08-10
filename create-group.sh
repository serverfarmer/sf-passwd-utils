#!/bin/bash
. /etc/farmconfig

if [ "$1" = "" ]; then
	echo "usage: $0 <group-name> [group-id]"
	exit 1
elif ! [[ $1 =~ ^[a-zA-Z0-9._-]+$ ]]; then
	echo "error: parameter 1 not conforming group name format"
	exit 1
elif [ "$2" != "" ] && ! [[ $2 =~ ^[0-9]+$ ]]; then
	echo "error: parameter 2 not numeric"
	exit 1
fi

group=$1

if [ "`getent group $group`" != "" ]; then
	echo "group $group already exists"
	exit 0
fi

if [ "$2" != "" ]; then
	gid=$2
	echo "creating group $group with GID=$gid"

	if [ "$OSTYPE" = "freebsd" ]; then
		pw groupadd $group -g $gid
	elif [ "$OSTYPE" != "qnap" ]; then
		groupadd -g $gid $group
	fi

else
	echo "creating group $group"

	if [ "$OSTYPE" = "freebsd" ]; then
		pw groupadd $group
	elif [ "$OSTYPE" != "qnap" ]; then
		groupadd $group
	fi
fi
