#!/bin/bash
# configuration file for other build scripts

source_level=${#BASH_SOURCE[@]}
test $source_level -eq 1 && { echo "Error: this file should be sourced by other build scripts" >&2; exit 1; }

if [[ -f /etc/lsb-release ]]; then
	source /etc/lsb-release
	export SYSTEM_RELEASE=${DISTRIB_ID}-${DISTRIB_RELEASE}
elif [[ -f /etc/redhat-release ]]; then
	redhat_release_re="\(([^\)]+)\)"
	if [[ $(cat /etc/redhat-release) =~ $redhat_release_re ]]; then
		export REDHAT_RELEASE=${BASH_REMATCH[1]}
		export SYSTEM_RELEASE=$REDHAT_RELEASE
	else
		echo "redhat-release not recognized" >&2
	fi
else
	# check redhat release and set local paths according to it
	echo "unknown linux distribution" >&2
	return 1
fi

source ~/.karol_ports.rc
INSTALL_ROOT="${INSTALL_TOOLS:-${HOME}/tools/pkgs}"

# vim: set ts=4 sw=4 sts=4 syntax=bash et:
