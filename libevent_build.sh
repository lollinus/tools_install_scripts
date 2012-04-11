#!/bin/env sh

set -e
set -u

SCRIPTDIR=$(dirname $(readlink -f $0))
CONFIG=$SCRIPTDIR/$(basename $0 .sh).rc
if [ -e ${CONFIG} ]; then
    source ${CONFIG}
fi

#
# This script updates git working tree. Then builds and installs new release
# 
REPOSITORY="ssh://git@github.com/libevent/libevent.git"
PROJECTS="${HOME}/projects"
CLONE_DIR="${PROJECTS}/libevent"
BUILD_DIR="${PROJECTS}/libevent_build"

SHARED_INSTALL="${HOME}/install/share"
# todo recognize linux type properly
EXEC_INSTALL="${HOME}/install/RHEL5_$(uname -m)"

#
# Remove dead symlinks left after install
#
function clean_dead_symlinks() {
    find ${EXEC_INSTALL} -type l -not -exec test -r '{}' \; -exec rm '{}' \;
}

#
# remove previous install of libevent
#
function clean_previous_install() {
    find ${EXEC_INSTALL} -type f -name 'libevent*' -not -newer ${BUILD_DIR}/config.status -exec rm '{}' \;
}

function do_libevent_build() {
    mkdir -p ${BUILD_DIR}
    cd ${BUILD_DIR}
    ${CLONE_DIR}/configure --prefix=${SHARED_INSTALL} --exec-prefix=${EXEC_INSTALL} --enable-static
    make
    make install
}

while getopts ":p:" opt; do
    case $opt in
        p)
            PACKAGE=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        esac
done

DOWNLOADED=0
if [ ${PACKAGE} ]; then
    echo "Downloading package (${PACKAGE})"
    rm -rf ${PROJECTS}/libevent.tar.gz
    wget -t0 -c --no-check-certificate ${PACKAGE} -O ${PROJECTS}/libevent.tar.gz
    DOWNLOADED=$?
    if [ ${DOWNLOADED} -eq 0 ]; then
        # save last package given from commandline
        echo "PACKAGE=${PACKAGE}" > ${CONFIG}
    fi
else
    echo "Package not defined"
    exit 1
fi

if [[ $DOWNLOADED -eq 0 ]]; then
    rm -rf ${CLONE_DIR}
    mkdir -p ${CLONE_DIR}
    tar xzf ${PROJECTS}/libevent.tar.gz -C ${CLONE_DIR} --strip-components 1
else
    exit ${DOWNLOADED}
fi

do_libevent_build
clean_previous_install
rm -rf ${BUILD_DIR}

exit 0
