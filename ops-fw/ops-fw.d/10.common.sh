#!/bin/bash



add-user () {
	local name=${1:-suwei}
	local uid=${2:-900}
	local passwd=${3:-passwd@aws#3109}
	if_ubuntu && {
		useradd -d /home/$name -c 'suwei accounts' -m -G users,www-data,puppet -u $uid -U -s /bin/bash $name && \
		echo "$name:$passwd" | chpasswd
	} || {
		useradd -d /home/$name -c 'suwei accounts' -m -G users,nobody,puppet -u $uid -U -s /bin/bash $name && \
		echo "$name:$passwd" | chpasswd
	}
}

add-sys-user () {
	local name=${1:-suwei}
	local uid=${2:-900}
	local passwd=${3:-passwd@aws#3109}
	if_ubuntu && {
		useradd -d /home/$name -c 'suwei accounts' -m -G users,www-data,puppet,sudo -r -u $uid -U -s /bin/bash $name && \
		echo "$name:$passwd" | chpasswd
	} || {
		useradd -d /home/$name -c 'suwei accounts' -m -G users,nobody,puppet -r -u $uid -U -s /bin/bash $name && \
		echo "$name:$passwd" | chpasswd
		[ -f /etc/sudoers ] && [ -d /etc/sudoers.d ] && {
			[ -f /etc/sudoers.d/$name ] || echo "$name	ALL=(ALL) 	ALL" > /etc/sudoers.d/$name
		}
	}
}

has-user () {
	local name=$1
	cat /etc/passwd|awk -F: '{print $1}'|grep -P "^$name$" >/dev/null
}




