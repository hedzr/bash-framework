#!/bin/bash

install () { commander "$@";}
install-usage () {
	cat <<EOF
Usage: $0 $self <sub-command> [...]
Sub-commands:
  self                   upgrade ME (bash-framework)
  self-as-root
  self-to-current-user
  bash-auto-completion   enable bash auto-completion supports for $OPS_NAME toolset

EOF
}

config () { commander "$@";}
config-usage () {
	cat <<EOF
Usage: $0 $self <sub-command> [...]
Sub-commands:
  grep [string]          find out the processes

EOF
}

tune () { commander "$@";}
tune-usage () {
	cat <<EOF
Usage: $0 $self <sub-command> [...]
Sub-commands:
  grep [string]          find out the processes

EOF
}



install-self () {
	install-self-to-current-user "$@"
	install-self-as-root "$@"
}

install-self-to-current-user () {
	local TGT="$HOME/$(basename $CD)"
	sudo test -d "$TGT" || sudo mkdir -p "$TGT"
	local brc="$HOME/.bashrc"
	append-ops-env "$brc" "$1"
}

install-self-as-root () {
	local TGT="/root/$(basename $CD)"
	sudo test -d "$TGT" || sudo mkdir -p "$TGT"

	echo "Setting up the target : $TGT"
	for f in $CD/* $CD/.[!.]*; do
		sudo cp -Rvp $f $TGT/
	done

	local brc=/root/.bashrc
	append-ops-env $brc
	make-sshd-keepalive
	allow-sshd-root

}


install-bash-auto-completion () {
	if [ -f /etc/bash_completion.d/ops_ac ]; then
		install-bash-auto-completion-impl
	else
		install-bash-auto-completion-impl
	fi
}

install-bash-auto-completion-impl () {
	cat >/etc/bash_completion.d/ops_ac <<EOC

shopt -s progcomp

_upstart_cmd_help_events () {
  $OPS_HOME_CMD \$1 help|grep "^  [^ \\\$\\#\\!/\\\\@\\"']"|awk '{print \$1}'
}

# _is_ubuntu () {
#   [ -f /etc/os-release ] && grep -i 'ubuntu' /etc/os-release >/dev/null
# }

_upstart_cmd () {
  #cmd=ops

  local cur prev sysvdir services options

  if [[ \$(type -t _get_comp_words_by_ref) == function ]]; then
    _get_comp_words_by_ref cur prev
  else
    cur=`_get_cword`
    prev=\${COMP_WORDS[COMP_CWORD-1]}
  fi

  # if [[ \$OSTYPE == *linux* ]]; then
  #   if _is_ubuntu; then
  #     cur=`_get_cword`
  #     prev=\${COMP_WORDS[COMP_CWORD-1]}
  #   else
  #     _get_comp_words_by_ref cur prev
  #   fi
  # else
  #   false
  # fi
  # echo "ops: '$cur' '$prev' --- " >> /tmp/1

  COMPREPLY=()

  case "\$prev" in
    --help|--version|usage|help)
      COMPREPLY=()
      return 0
      ;;
  esac

  #opts="--help --version -q --quiet -v --verbose --system --dest="
  #opts="--help upgrade version deploy undeploy log ls ps start stop restart"
  opts="--help"
  #cmds=\$(ops help|grep "^  [^ \\\\$\\#\\!\/\\\\@\\"']"|awk '{print \$1}')
  cmds="\$(_upstart_cmd_help_events \$prev)"

  COMPREPLY=( \$(compgen -W "\${opts} \${cmds}" -- \${cur}) )

} && complete -F _upstart_cmd ops
#complete -F _bzr_lazy -o default bzr

EOC

	cat <<EOF

Installed.
Re-login the current shell session to bring '$OPS_NAME' auto-completion feature up.
Type '$OPS_NAME<TAB><TAB>', ...
Enjoy it!

EOF
}


make-sshd-keepalive () {
	local ss=/etc/ssh/sshd_config
	local flag=1
	if grep -P "^ClientAliveInterval" $ss; then
	  echo "ClientAliveCountMax ok, in $ss."
	else
		if grep -P "^#+ClientAliveInterval" $ss; then
			sudo perl -0777 -i.original -pe 's/^#+ClientAliveInterval.*$/ClientAliveInterval 60/igsm' $ss
		else
			echo "ClientAliveInterval 60" | sudo tee -a $ss
		fi
		flag=0
	fi
	if grep -P "^ClientAliveInterval [^6]" $ss; then
		flag=0
		sudo sed -i -r 's/^ClientAliveInterval.*$/ClientAliveInterval 60/i' $ss
	fi

	if grep -P "^ClientAliveCountMax" $ss; then
		echo "ClientAliveCountMax ok, in $ss."
	else
		if grep -P "^#+ClientAliveCountMax" $ss; then
			sudo perl -0777 -i.original -pe 's/^#+ClientAliveCountMax.*$/ClientAliveCountMax 6/igsm' $ss
		else
			echo "ClientAliveCountMax 6" | sudo tee -a $ss
		fi
		flag=0
	fi
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

append-ops-env-old () {
	local brc=${1:-/root/.bashrc}; shift
	sudo grep -P '^\[ -f "\$HOME\/bin\/\.env" \]' $brc && {
		sudo perl -0777 -i.original -pe 's/^\[ -f "\$HOME\/bin\/\.env" \]$/\[ -f "\$HOME\/bin\/\.env" \] && export OPS_BASE=\$HOME\/bin && PATH=\$OPS_BASE:\$PATH && \. \$OPS_BASE\/\.env && at_login/igsm' $brc
	} || {
		echo '[ -f "$HOME/bin/.env" ] && export OPS_BASE=$HOME/bin && PATH=$OPS_BASE:$PATH && . $OPS_BASE/.env && at_login' | sudo tee -a $brc;
	}
}

append-ops-env () {
	local brc=${1:-/root/.bashrc}; shift
	local IN=${2:-ops-fw}
	if sudo grep -P "^\[ -f \\\"\/usr\/local\/bin\/$IN\/\.env\\\" \]" $brc; then
		sudo perl -0777 -i.original -pe 's/^\[ -f "\/usr\/local\/bin\/ops\-fw\/\.env" \][^\n]*$/\[ -f "\/usr\/local\/bin\/ops\-fw\/\.env" \] && export OPS_BASE=\/usr\/local\/bin\/ops\-fw && \. \$OPS_BASE\/\.env && at_login/igsm' $brc
	else
		echo -e "[ -f \"/usr/local/bin/$IN/.env\" ] && export OPS_BASE=/usr/local/bin/$IN && . \$OPS_BASE/.env && at_login\nPATH=/usr/local/bin:\$PATH\n" | sudo tee -a $brc;
	fi
	
	local prc=$(dirname $brc) pf;
	if [ -f $prc/.profile ]; then pf=$prc/.profile; else pf=$prc/.bash_profile; fi
	
	DEBUG "Modifying $pf..."
	if sudo grep -P '^\. \$OPS_BASE/\.alias' $pf; then
		#sudo perl -0777 -i.original -pe 's/^\. \$OPS_BASE/\.alias$/\. \$OPS_BASE/\.alias/igsm' $pf
		:
	else
		echo '. $OPS_BASE/.alias' | sudo tee -a $pf;
	fi
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














