#!/bin/bash
. /etc/farmconfig

if [ "$1" = "" ]; then
	echo "usage: $0 <user-name> <group-name> [group-name] [...]"
	exit 1
elif ! [[ $1 =~ ^[a-zA-Z0-9._-]+$ ]]; then
	echo "error: parameter 1 not conforming user name format"
	exit 1
elif [ "`getent passwd $1`" = "" ]; then
	echo "error: user $1 not found"
	exit 1
fi

user=$1
shift

for group in $@; do
	if [ "`getent group $group`" = "" ]; then
		echo "warning: group $group not found, skipping"
	elif ! [[ $group =~ ^[a-zA-Z0-9._-]+$ ]]; then
		echo "warning: given group name not conforming group name format, skipping"
	elif [ "$OSTYPE" = "freebsd" ]; then
		pw usermod $user -aG $group
	elif [ "$OSTYPE" != "qnap" ]; then
		usermod -aG $group $user
	fi
done
