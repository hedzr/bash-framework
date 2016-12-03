#!/bin/bash


install () {
	local subcmd=$1; shift
	case $subcmd in
		self) install-self $*; ;;
		*)    install-$subcmd $*; ;;
	esac
}
config () {
	local subcmd=$1; shift
	case $subcmd in
		self) config-self $*; ;;
		*)    config-$subcmd $*; ;;
	esac
}
tune () {
	local subcmd=$1; shift
	case $subcmd in
		self) tune-self $*; ;;
		*)    tune-$subcmd $*; ;;
	esac
}

install-self () {
	install-self-to-current-user $*
	install-self-as-root $*
}

install-self-to-current-user () {
	local TGT=$HOME/$(basename $CD)
	sudo test -d $TGT || sudo mkdir -p $TGT
	local brc=$HOME/.bashrc
	append-ops-env $brc
}

install-self-as-root () {
	local TGT=/root/$(basename $CD)
	sudo test -d $TGT || sudo mkdir -p $TGT

	echo "Setting up the target : $TGT"
	for f in $CD/* $CD/.[!.]*; do
		sudo cp -Rvp $f $TGT/
	done

	local brc=/root/.bashrc
	append-ops-env $brc
	make-sshd-keepalive
	allow-sshd-root

}


make-sshd-keepalive () {
	local ss=/etc/ssh/sshd_config
	local flag=1
	grep -P "^ClientAliveInterval" $ss && echo "ClientAliveCountMax ok, in $ss." || {
		grep -P "^#+ClientAliveInterval" $ss && \
		sudo perl -0777 -i.original -pe 's/^#+ClientAliveInterval.*$/ClientAliveInterval 60/igsm' $ss || \
		echo "ClientAliveInterval 60" | sudo tee -a $ss
		flag=0
	}
	grep -P "^ClientAliveInterval [^6]" $ss && flag=0 && sudo sed -i -r 's/^ClientAliveInterval.*$/ClientAliveInterval 60/i' $ss

	grep -P "^ClientAliveCountMax" $ss && echo "ClientAliveCountMax ok, in $ss." || {
		grep -P "^#+ClientAliveCountMax" $ss && \
		sudo perl -0777 -i.original -pe 's/^#+ClientAliveCountMax.*$/ClientAliveCountMax 6/igsm' $ss || \
		echo "ClientAliveCountMax 6" | sudo tee -a $ss
		flag=0
	}
	grep -P "^ClientAliveCountMax [^6]" $ss && flag=0 && sudo sed -i -r 's/^ClientAliveCountMax.*$/ClientAliveCountMax 6/i' $ss

	[ -z $flag ] && sudo service sshd restart
}

allow-sshd-root () {
	local ss=/etc/ssh/sshd_config
	local flag=1
	grep -P "^PermitRootLogin yes" $ss && echo "PermitRootLogin yes ok, in $ss." || {
		grep -P "^#+PermitRootLogin yes" $ss && \
		sudo perl -0777 -i.original -pe 's/^#+PermitRootLogin yes$/PermitRootLogin yes/igsm' $ss || \
		echo "PermitRootLogin yes" | sudo tee -a $ss
		flag=0
	}

	grep -P "^#PermitRootLogin forced-commands-only" $ss && echo "#PermitRootLogin forced-commands-only ok, in $ss." || {
		grep -P "^PermitRootLogin forced-commands-only" $ss && \
		sudo perl -0777 -i.original -pe 's/^PermitRootLogin forced-commands-only$/#PermitRootLogin forced-commands-only/igsm' $ss
		flag=0
	}

	[ -z $flag ] && sudo service sshd restart
}

setup-pm () {
	if_centos && {
		sudo yum install epel-release
	} || {
		#sudo apt-get update;
		true
	}
}

append-ops-env () {
	local brc=${1:-/root/.bashrc}; shift
	sudo grep -P '^\[ -f "\$HOME\/bin\/\.env" \]' $brc && {
		sudo perl -0777 -i.original -pe 's/^\[ -f "\$HOME\/bin\/\.env" \]$/\[ -f "\$HOME\/bin\/\.env" \] && export OPS_BASE=\$HOME\/bin && PATH=\$OPS_BASE:\$PATH && \. \$OPS_BASE\/\.env && at_login/igsm' $brc
	} || {
		echo '[ -f "$HOME/bin/.env" ] && export OPS_BASE=$HOME/bin && PATH=$OPS_BASE:$PATH && . $OPS_BASE/.env && at_login' | sudo tee -a $brc;
	}
}







test () {
	sudo ~/bin/suwei-init help
}

install-nginx () {
	if is_root; then
		install-packages nginx
		config-nginx
		nginx -v
		if_centos && chkconfig nginx on
		service nginx restart
	else
		echo "# 非root账户：传送到root账户下重新执行……`id -u`"
		if [ "`id -u`" == "0" ]; then
			true
		else
			install-self
			echo "# 已经完成传送，开始执行：sudo /root/bin/$(basename $0) $cmd $subcmd $*"
			sudo /root/bin/$(basename $0) $cmd $subcmd $*
		fi
	fi
}

config-nginx () {
	false
}

_sudo_tune_nginx () {
	FILE_NUM=100000

	echo "# TUNE NGINX……"
	local ff=/etc/nginx/nginx.conf
	[ ! -f $ff.auto-bak ] && cp $ff{,.auto-bak}
	
	grep 'worker_rlimit_nofile ' $ff || perl -0777 -i.original -pe  "s#pid /var/run/nginx.pid;[^\n]*$#pid /var/run/nginx.pid;
worker_rlimit_nofile $FILE_NUM;
use epoll;
multi_accept on;
#igms" $ff
		sed -i -r "s#worker_connections 1024;#worker_connections $FILE_NUM;#" $ff
		grep 'worker_connections ' $ff || perl -0777 -i.original -pe  "s#worker_connections[^\n]*$#worker_connections $FILE_NUM;
#igms" $ff
		grep 'client_header_buffer_size ' $ff || perl -0777 -i.original -pe  "s#keepalive_timeout   65;[^\n]*$#keepalive_timeout   65;
    client_header_buffer_size 4k;
    open_file_cache max=$FILE_NUM inactive=25s;
    open_file_cache_valid 50s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
#igms" $ff

		ff=/etc/sysctl.conf
		grep 'net.ipv4.tcp_syn_retries' $ff || cat >>$ff<<EOF

##JY
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024 65000

EOF
	/sbin/sysctl -p

	ff=/etc/security/limits.conf
	grep "soft nofile $FILE_NUM" $ff || { cat >>$ff<<EOF
* soft nofile $FILE_NUM
* hard nofile $FILE_NUM
* soft nproc $FILE_NUM
* hard nproc $FILE_NUM
EOF
		echo "ulimit -n 已经修改到 $FILE_NUM，但可能需要 reboot 后才能生效。"
		ulimit -n $FILE_NUM
		if_centos || {
			# Debian 系使用 limits.conf 不是太能生效，需要附加启动脚本来确保
			grep "ulimit -SHn $FILE_NUM" /etc/profile || [ -f /etc/profile.d/10.ulimit.sh ] || echo "ulimit -SHn $FILE_NUM" >/etc/profile.d/10.ulimit.sh
		}
	}
	service nginx restart
	#
}

# 压测指令：-c 并发数，-n 请求数
# 
# ab -n 1000 -kc 1000 http://54.223.119.73/
# ab -n 7000 -kc 1000 http://54.223.119.73/
# ab -n 500000 -kc 5000 http://54.223.119.73/
# ab -n 500000 -kc 2500 http://54.223.119.73/
# 
tune-nginx () {
	if is_root; then
		_sudo_tune_nginx $*
	else
		echo "# 非root账户：传送到root账户下重新执行……"
		install-self
		echo "# 已经完成传送，开始执行：sudo -i /root/bin/$(basename $0) $cmd $subcmd $*"
		sudo /root/bin/$(basename $0) $cmd $subcmd $*
		echo "# 执行完毕"
	fi
}














