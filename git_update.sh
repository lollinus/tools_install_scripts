#!/bin/env sh

set -e
set -u
#
# This script updates git working tree. Then builds and installs new release
# 
CURRENT_DIR=${PWD}

REPOSITORY="http://github.com/gitster/git.git"
PROJECTS="${HOME}/projects"
CLONE_DIR="${PROJECTS}/git"
BUILD_DIR="${PROJECTS}/git"

SHARED_INSTALL="${HOME}/install/share"
# todo recognize linux type properly
EXEC_INSTALL="${HOME}/install/RHEL5_$(uname -m)/emacs"

# check if clone dir exists
if [ ! -e ${CLONE_DIR} ]; then
    echo "${CLONE_DIR} not exist -> new clone"
    mkdir -p ${PROJECTS}
    git clone ${REPOSITORY} ${CLONE_DIR}
elif [ ! -d ${CLONE_DIR} ]; then
    # @TODO handle properly when CLONE_DIR exists but is not an directory
    echo "not a directory ${CLONE_DIR}"
    exit 1;
else
    # @TODO check if we have clone wchich should be pulled
    # right now only pull
    echo "Pull directory"
    cd ${CLONE_DIR} && git fetch origin && git pull origin master && make configure
    if [[ 0 -ne $? ]]; then
        echo "Pull failed"
        exit 1;
    fi
fi

cd ${BUILD_DIR}
${CLONE_DIR}/configure --prefix=/home/barskkar/install/share/ --exec-prefix=/home/barskkar/install/RHEL5_x86_64/git/ 
make
make install
make doc
make install-doc
git clean -d -x -f
cd ${CURRENT_DIR}

exit 0
