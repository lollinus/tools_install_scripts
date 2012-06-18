#!/bin/bash

set -e
set -u
#
# Script to update emacs source from repository and then build
#
# emacs git repository: http://git.savannah.gnu.org/r/emacs.git

REPOSITORY="http://git.savannah.gnu.org/r/emacs.git"
PROJECTS="${HOME}/projects"
CLONE_DIR="${PROJECTS}/emacs"
BUILD_DIR="${PROJECTS}/emacs_build"

SHARED_INSTALL="${HOME}/install/share"
# todo recognize linux type properly
EXEC_INSTALL="${HOME}/install/RHEL5_$(uname -m)/emacs"
BRANCH="master"
TAG=
INSTALL=Y
while getopts ":b:t:n" opt "$@"; do
    case $opt in
        b)
            BRANCH=$OPTARG
            ;;
        t)
            TAG=$OPTARG
            BRANCH=$OPTARG
            ;;
        n)
            INSTALL=
            ;;
        *)
            echo "unknown option $OPTIND ($opt) ($OPTARG)"
            ;;
    esac
done
OPTIND=0;

# check if clone dir exists
if [ ! -e ${CLONE_DIR} ]; then
    echo "${CLONE_DIR} not exist -> new clone"
    clone_command="mkdir -p ${PROJECTS}; git clone ${REPOSITORY} ${CLONE_DIR}; cd ${CLONE_DIR}; git checkout -t -b ${BRANCH} ${TAG:-origin/${BRANCH}}"
    eval $clone_command
elif [ ! -d ${CLONE_DIR} ]; then
    # @TODO handle properly when CLONE_DIR exists but is not an directory
    echo "not a directory ${CLONE_DIR}"
    exit 1;
else
    # @TODO check if we have clone wchich should be pulled
    # right now only pull
    echo "Pull directory"
    pushd ${CLONE_DIR};
    if [[ $(git show-ref --verify --quiet 'refs/heads/${BRANCH}') -ne 0 ]]; then
        pull_command="cd ${CLONE_DIR} && git fetch origin && git checkout -b ${BRANCH} ${TAG:-origin/${BRANCH}}"
        if [[ -z $TAG ]]; then
            pull_command+="&& git pull origin ${BRANCH}"
        fi
    else
        pull_command="cd ${CLONE_DIR} && git fetch origin && git checkout -f ${BRANCH} && git reset --hard ${TAG:-origin/${BRANCH}}"
    fi
    popd
    set -v
    eval $pull_command
    set +v
    if [[ 0 -ne $? ]]; then
        echo "Pull failed"
        exit 1;
    fi
fi

# we have updated sources. time to configure.
cd ${CLONE_DIR} && ./autogen.sh
rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}

# cleanup
[[ -n "${INSTALL}" ]] && {
    echo "Install enabled setting trap"
    trap 'rm -rf ${BUILD_DIR}' EXIT
}

cd ${BUILD_DIR}
# configure with x-toolkit set to lucid - default gnome2 toolking causes hangups in case of remote work and connection break.
${CLONE_DIR}/configure --prefix=${SHARED_INSTALL} --exec-prefix=${EXEC_INSTALL} --with-x-toolkit=lucid
make
if [[ $? -eq 0 ]]; then
    exit $?
fi
[[ -n "${INSTALL}" ]] && {
    make install
} || {
    echo "Install disabled"
}

exit 0
