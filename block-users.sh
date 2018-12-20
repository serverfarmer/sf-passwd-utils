#!/bin/bash
. /etc/farmconfig
. /opt/farm/scripts/functions.custom

admin=`primary_admin_account`

if [ "$1" = "" ]; then
	echo "usage: $0 <user-name> [user-name] [...]"
	exit 1
fi

for user in $@; do
	if ! [[ $user =~ ^[a-zA-Z0-9._-]+$ ]]; then
		echo "warning: given user name not conforming user name format, skipping"
	elif [ "$user" = "root" ]; then
		echo "warning: blocking root impossible, skipping"
	elif [ "$user" = "$admin" ]; then
		echo "warning: blocking user $admin impossible, skipping"
	else
		existing=`getent passwd $user`
		if [ "$existing" != "" ]; then

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
		fi
	fi
done
