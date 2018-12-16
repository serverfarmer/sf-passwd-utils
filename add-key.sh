#!/bin/bash
. /etc/farmconfig

if [ "$3" = "" ]; then
	echo "usage: $0 <user-name> <file/inline> <key-material>"
	exit 1
elif ! [[ $1 =~ ^[a-zA-Z0-9._-]+$ ]]; then
	echo "error: parameter 1 not conforming user name format"
	exit 1
elif [ "$2" != "file" ] && [ "$2" != "inline" ]; then
	echo "error: invalid mode (should be either \"file\" or \"inline\")"
	exit 1
fi

user=$1
mode=$2

if [ "`getent passwd $user`" = "" ]; then
	exit 0
fi

if [ "$mode" != "file" ]; then
	keytext="$3"
elif [ -f $3 ]; then
	keytext="`head -n1 $3`"
else
	echo "error: key $3 not found"
	exit 0
fi

if ! [[ "$keytext" =~ ^ssh-[a-zA-Z0-9/@\ .:+_-]+$ ]]; then
	echo "error: given key \"$keytext\" is incomplete or invalid"
	exit 0
fi

home=`getent passwd $user |cut -d: -f6`

if [ ! -f $home/.ssh/authorized_keys ] || ! grep -q "$keytext" $home/.ssh/authorized_keys; then
	mkdir -p $home/.ssh
	echo "$keytext" >>$home/.ssh/authorized_keys
fi
