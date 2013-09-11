#!/bin/bash
# configuration file for other build scripts

source_level=${#BASH_SOURCE[@]}
test $source_level -eq 1 && { echo "Error: this file should be sourced by other build scripts" >&2; exit 1; }

    # check redhat release and set local paths according to it
if ! [[ -f /etc/redhat-release ]]; then
    echo "unknown linux distribution" >&2
    return 1
fi
redhat_release_re="\(([^\)]+)\)"
if [[ $(cat /etc/redhat-release) =~ $redhat_release_re ]]; then
    export REDHAT_RELEASE=${BASH_REMATCH[1]}
    export SYSTEM_RELEASE=$REDHAT_RELEASE
else
    echo "redhat-release not recognized" >&2
fi

INSTALL_ROOT="${HOME}/tools/pkgs"
