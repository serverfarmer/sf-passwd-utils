#!/bin/bash
. /etc/farmconfig
. /opt/farm/scripts/functions.custom

admin=`primary_admin_account`

if [ "$1" = "" ]; then
	echo "usage: $0 <user-name>"
	exit 1
elif ! [[ $1 =~ ^[a-zA-Z0-9._-]+$ ]]; then
	echo "error: parameter 1 not conforming user name format"
	exit 1
elif [ "$1" = "root" ]; then
	echo "error: blocking root impossible"
	exit 1
elif [ "$1" = "$admin" ]; then
	echo "error: blocking user $admin impossible"
	exit 1
fi

user=$1
existing=`getent passwd $user`

if [ "$existing" = "" ]; then
	exit 0
fi

password=`getent shadow $user |cut -d: -f2`
if [[ ${password:0:1} != "-" ]] && [[ ${password:0:1} != "*" ]]; then
	echo "locking password for user $user"
	passwd -l $user
fi

home=`echo $existing |cut -d: -f6`
keys=$home/.ssh/authorized_keys

if [ -s $keys ]; then
	echo "disabling ~/.ssh/authorized_keys file for user $user"
	mv -f $keys ${keys}_disabled_`date +%Y%m%d%H%M`
fi

shell=`echo $existing |cut -d: -f7`
if [ "$shell" != "/bin/false" ]; then
	echo "changing login shell for user $user from $shell to /bin/false"

	if [ "$OSTYPE" = "freebsd" ]; then
		pw usermod $user -s /bin/false
	elif [ "$OSTYPE" != "qnap" ]; then
		usermod -s /bin/false $user
	fi
fi
