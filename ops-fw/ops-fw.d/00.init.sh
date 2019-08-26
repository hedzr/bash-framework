#!/bin/bash

help () {
	echo help
}

usage () {
	echo usage
}

commander () {
  local cmd=${1:-usage}; [ $# -eq 0 ] || shift;
  local self=${FUNCNAME[0]}
  case $cmd in
    help|usage|--help|-h|-H) "$self-usage" "$@"; ;;
    *) "$self-$cmd" "$@"; ;;
  esac
}


git () { commander "$@";}
git-usage () {
	cat <<EOF
Usage: $0 $self <sub-command> [...]
Sub-commands:
  proxy set <proxy-url>  upgrade ME (bash-framework)
  proxy unset
  tune                   enlarge postbuffer, disable https verify check

EOF
}

git-proxy-set () {
	git config --global http.proxy $1
	git config --global https.proxy $1
}

git-proxy-unset () {
	git config --global --unset http.proxy
	git config --global --unset https.proxy
}

git-tune () {
	git config http.postbuffer 524288000
	git config http.sslverify false
}

: