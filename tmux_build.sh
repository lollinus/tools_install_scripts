#!/bin/env sh

set -e
set -u
#
# This script updates git working tree. Then builds and installs new release
# 
CURRENT_DIR=${PWD}

REPOSITORY="https://tmux.svn.sourceforge.net/svnroot/tmux"
PROJECTS="${HOME}/projects"
CLONE_DIR="${PROJECTS}/tmux"
BUILD_DIR="${PROJECTS}/tmux"

SHARED_INSTALL="${HOME}/install/share"
# todo recognize linux type properly
EXEC_INSTALL="${HOME}/install/RHEL5_$(uname -m)/tmux"

echo "NOT FINISHED"
exit 1

# check if clone dir exists
if [ ! -e ${CLONE_DIR} ]; then
    echo "${CLONE_DIR} not exist -> new clone"
    mkdir -p ${PROJECTS}
    git svn clone --stdlayout  ${REPOSITORY} ${CLONE_DIR}
elif [ ! -d ${CLONE_DIR} ]; then
    # @TODO handle properly when CLONE_DIR exists but is not an directory
    echo "not a directory ${CLONE_DIR}"
    exit 1;
else
    # @TODO check if we have clone wchich should be pulled
    # right now only pull
    echo "Pull directory"
    cd ${CLONE_DIR} && git svn fetch origin && git svn rebase && make configure
    if [[ 0 -ne $? ]]; then
        echo "Pull failed"
        exit 1;
    fi
fi

cd ${BUILD_DIR}
${CLONE_DIR}/configure --prefix=${SHARED_INSTALL} --exec-prefix=${EXEC_INSTALL}
make
make install
make doc
make install-doc
git clean -d -x -f
cd ${CURRENT_DIR}

exit 0
