#!/bin/bash

help () {
	echo help
}

usage () {
	echo usage
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

true