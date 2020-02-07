#!/bin/bash
. /etc/farmconfig

if [ "$1" = "" ]; then
	echo "usage: $0 <user-name> <group-name> [group-name] [...]"
	exit 1
elif ! [[ $1 =~ ^[a-zA-Z0-9._-]+$ ]]; then
	echo "error: parameter 1 not conforming user name format"
	exit 1
fi

user=$1
shift

if [ "`getent passwd $user`" = "" ]; then
	exit 0
fi

for group in $@; do
	if ! [[ $group =~ ^[a-zA-Z0-9._-]+$ ]]; then
		echo "warning: given group name not conforming group name format, skipping"
	elif [ "`getent group $group`" = "" ]; then
		:
	elif [ "$OSTYPE" = "freebsd" ]; then
		echo "adding user $user to group $group"
		pw usermod $user -aG $group
	elif [ "$OSTYPE" != "qnap" ]; then
		echo "adding user $user to group $group"
		usermod -aG $group $user
	fi
done
