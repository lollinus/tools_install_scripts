#!/bin/bash

set -e
set -u
#
# Script to update emacs source from repository and then build
#
# emacs git repository: http://git.savannah.gnu.org/r/emacs.git

CURRENT_DIR=${PWD}
REPOSITORY="http://git.savannah.gnu.org/r/emacs.git"
PROJECTS="${HOME}/projects"
CLONE_DIR="${PROJECTS}/emacs"
BUILD_DIR="${PROJECTS}/emacs_build"

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
    cd ${CLONE_DIR} && git fetch origin && git pull origin master&& ./autogen.sh
    if [[ 0 -ne $? ]]; then
        echo "Pull failed"
        exit 1;
    fi
fi

# we have updated sources. time to configure.
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
# configure with x-toolkit set to lucid - default gnome2 toolking causes hangups in case of remote work and connection break.
${CLONE_DIR}/configure --prefix=${SHARED_INSTALL} --exec-prefix=${EXEC_INSTALL} --with-x-toolkig=lucid
make && make install
cd ${CURRENT_DIR}

exit 0
