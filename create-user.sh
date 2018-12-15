#!/bin/bash
. /etc/farmconfig
. /opt/farm/ext/passwd-utils/functions

if [ "$2" = "" ]; then
	echo "usage: $0 <group-name> <user-name> [+][user-id] [-][home-dir] [shell]"
	exit 1
elif ! [[ $1 =~ ^[a-zA-Z0-9._-]+$ ]]; then
	echo "error: parameter 1 not conforming group name format"
	exit 1
elif ! [[ $2 =~ ^[a-zA-Z0-9._-]+$ ]]; then
	echo "error: parameter 2 not conforming user name format"
	exit 1
elif [ "$3" != "" ] && ! [[ $3 =~ ^[+]?[0-9]+$ ]]; then
	echo "error: parameter 3 not conforming uid format"
	exit 1
elif [ "$5" != "" ] && [ ! -x $5 ]; then
	echo "error: given shell path is invalid"
	exit 1
fi

group=$1
user=$2
userid=$3
home=$4
homedir="/home/$user"
shell=/bin/bash

# uid:
#  3000  - use uid=3000
#  +3000 - find first unused uid starting from 3000
#  empty - find first unused uid starting from default 1000
#
if [ "$userid" != "" ] && [[ ${userid:0:1} = "+" ]]; then
	uid=`get_free_uid ${userid:1} 65530`
elif [ "$userid" = "" ]; then
	uid=`get_free_uid 1000 65530`
else
	uid=$userid
fi

# home directory:
#  empty        - create,        use default /home/$user
#  -            - skip creating, use default /home/$user
#  /data/$user  - create,        first check if /data exists
#  -/data/$user - skip creating, first check if /data exists
#
if [ "$home" != "" ] && [[ ${home:0:1} = "-" ]]; then
	home=${home:1}
	create_bsd=""
	create_linux="-M"
else
	create_bsd="-m"
	create_linux="-m"
fi

if [ "$home" != "" ]; then
	homedir=$home
	parent=`dirname $homedir`
	if [ ! -d $parent ]; then
		echo "error: home parent directory $parent not exists"
		exit 0
	fi
fi

if [ "$5" != "" ]; then
	shell=$5
fi

if [ "`getent group $group`" = "" ]; then
	echo "creating group $group"

	if [ "$OSTYPE" = "freebsd" ]; then
		pw groupadd $group
	elif [ "$OSTYPE" != "qnap" ]; then
		groupadd $group
	fi
fi

existing=`getent passwd $user`

if [ "$existing" = "" ]; then
	# user not exists yet, create
	echo "creating user $user (group $group) with UID=$uid, directory $homedir, login shell $shell"

	if [ "$OSTYPE" = "freebsd" ]; then
		pw useradd $user $create_bsd -d $homedir -s $shell -g $group -u $uid
	elif [ "$OSTYPE" != "qnap" ]; then
		useradd $create_linux -d $homedir -s $shell -g $group -u $uid $user
	fi

else  # user already exists, enforce given shell and warn if UID or home directory are different
	echo "user $user already exists"

	exuid=`echo $existing |cut -d: -f3`
	if [ "$exuid" != "$uid" ]; then
		echo "warning: $user has UID=$exuid (different than specified $uid)"
	fi

	exhome=`echo $existing |cut -d: -f6`
	if [ "$exhome" != "$homedir" ]; then
		echo "warning: $user has home directory $exhome (different than specified $homedir)"
	fi

	exshell=`echo $existing |cut -d: -f7`
	if [ "$exshell" != "$shell" ]; then
		echo "changing login shell for user $user from $exshell to $shell"

		if [ "$OSTYPE" = "freebsd" ]; then
			pw usermod $user -s $shell
		elif [ "$OSTYPE" != "qnap" ]; then
			usermod -s $shell $user
		fi
	fi
fi
