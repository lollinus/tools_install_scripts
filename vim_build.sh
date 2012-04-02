#!/bin/bash

set -e
set -u
#
# Script to update vim source from repository and then build
#
# vim mercurial repository: https://vim.googlecode.com/hg/

CURRENT_DIR=${PWD}
REPOSITORY="https://vim.googlecode.com/hg/"
PROJECTS="${HOME}/projects"
CLONE_DIR="${PROJECTS}/vim"
BUILD_DIR="${PROJECTS}/vim"     # configure does not work properly in out of source build

SHARED_INSTALL="${HOME}/install/share"
# todo recognize linux type properly
EXEC_INSTALL="${HOME}/install/RHEL5_$(uname -m)/vim"

# check if clone dir exists
if [ ! -e ${CLONE_DIR} ]; then
    echo "${CLONE_DIR} not exist -> new clone"
    mkdir -p ${PROJECTS}
    hg clone ${REPOSITORY} ${CLONE_DIR}
elif [ ! -d ${CLONE_DIR} ]; then
    # @TODO handle properly when CLONE_DIR exists but is not an directory
    echo "not a directory ${CLONE_DIR}"
    exit 1;
else
    # @TODO check if we have clone wchich should be pulled
    # right now only pull
    echo "Pull directory"
    cd ${CLONE_DIR} && hg pull origin
    if [[ 0 -ne $? ]]; then
        echo "Pull failed"
        exit 1;
    fi
fi

# we have updated sources. time to configure.
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
${CLONE_DIR}/configure --prefix=${SHARED_INSTALL} --exec-prefix=${EXEC_INSTALL}
make && make install
cd ${CURRENT_DIR}

exit 0
