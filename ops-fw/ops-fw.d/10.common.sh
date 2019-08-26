#!/bin/bash


user () { commander "$@";}
user-usage () {
	cat <<EOF
Usage: $0 $self <sub-command> [...]
Sub-commands:
  add [--sys|-s] <name> [uid] [passwd]  Add normal/system account
  del <name>                            Delete an account
  exists <name>                         check user exists or not (return true = exists)

EOF
}
user-add () { add-user "$@"; }
user-del () { del-user "$@"; }
user-exists () { has-user "$@"; }

del-user () {
	echo "NOT YET"
}

add-user () {
	if [ $# -gt 1 ]; then
		local a1=$1
		local system=0
		case $a1 in
			--sys|--system|-s) system=1; shift; ;;
		esac

		local name=${1:-}
		local uid=${2:-}
		local passwd=${3:-passwd@aws#3109}
		shift 3
		local desc="$@"
		if if_ubuntu; then
			useradd -d /home/$name -c 'suwei accounts' -m -G users,www-data,puppet -u $uid -U -s /bin/bash $name && \
			echo "$name:$passwd" | chpasswd
		else
			useradd -d /home/$name -c 'suwei accounts' -m -G users,nobody,puppet -u $uid -U -s /bin/bash $name && \
			echo "$name:$passwd" | chpasswd
		fi
	else
		user-usage
	fi
}

add-sys-user () {
	local name=${1:-suwei}
	local uid=${2:-900}
	local passwd=${3:-passwd@aws#3109}
	if if_ubuntu; then
		useradd -d /home/$name -c 'suwei accounts' -m -G users,www-data,puppet,sudo -r -u $uid -U -s /bin/bash $name && \
		echo "$name:$passwd" | chpasswd
	else
		useradd -d /home/$name -c 'suwei accounts' -m -G users,nobody,puppet -r -u $uid -U -s /bin/bash $name && \
		echo "$name:$passwd" | chpasswd
		[ -f /etc/sudoers ] && [ -d /etc/sudoers.d ] && {
			[ -f /etc/sudoers.d/$name ] || echo "$name	ALL=(ALL) 	ALL" > /etc/sudoers.d/$name
		}
	fi
}

has-user () {
	local name=$1
	cat /etc/passwd|awk -F: '{print $1}'|grep -P "^$name$" >/dev/null
}




