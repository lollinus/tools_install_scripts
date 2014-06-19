#!/bin/bash
# vim: set ts=4 sts=4 sw=4 et: 

set -e
set -u

readonly my_dir=$(dirname ${BASH_SOURCE[0]})
readonly my_name=$(basename ${BASH_SOURCE[0]})
readonly my_pkg=$(basename ${BASH_SOURCE[0]} .sh)
#
# This script updates git working tree. Then builds and installs new release
# 
PROJECTS="${HOME}/projects"
CLONE_DIR="${PROJECTS}/$my_name"
BUILD_DIR=${BUILD_DIR:-${PROJECTS}/${my_name}-build}

source $my_dir/ports-config.sh
CONFIG=$my_dir/$(basename ${BASH_SOURCE[0]} .sh).rc
if [ -e ${CONFIG} ]; then
    source ${CONFIG}
fi

function unpack() {
	while getopts ":f:C:s:" opt "$@"; do
		case $opt in
			f)
			file=$OPTARG
			;;
			C)
			path=$OPTARG
			;;
			s)
			strip_components=$OPTARG
			;;
		esac
	done
	OPTIND=0
	
	local readonly tar_gzip_re="\.[tT]([aA][rR]\.)?[gG][zZ]$"
	local readonly tar_bzip2_re="\.[tT]([aA][rR]\.)?[bB][zZ]2?$"
	local readonly tar_xz_re="\.[tT]([aA][rR]\.)?[xX][zZ]$"
	if [[ $file =~ $tar_gzip_re ]]; then
		tar xvf $file ${path:+-C $path} ${strip_components:+--strip-components=$strip_components}
	elif [[ $file =~ $tar_bzip2_re ]]; then
		tar xjf $file ${path:+-C $path} ${strip_components:+--strip-components=$strip_components}
	elif [[ $file =~ $tar_xz_re ]]; then
		xz -dc $file | tar x ${path:+-C $path} ${strip_components:+--strip-components=$strip_components}
	else
		echo "WTF $file" >&2
	fi
}

USE_CHECKOUT=
SKIP_DOWNLOAD=
while getopts ":p:cs" opt; do
    case $opt in
        p)
            PACKAGE=$OPTARG
            ;;
        c)
            USE_CHECKOUT=Y
            ;;
        s)
            echo "-s option" >&2
            SKIP_DOWNLOAD=Y
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        esac
done
OPTIND=0;

DOWNLOADED=0

function fetch_git() {
    echo "Fetch from GIT repository"
    # check if clone dir exists
    if [ ! -e ${CLONE_DIR} ]; then
        echo "${CLONE_DIR} not exist -> new clone"
        mkdir -p ${PROJECTS}
        git clone ${REPOSITORY_GIT} ${CLONE_DIR}
    elif [ ! -d ${CLONE_DIR} ]; then
        # @TODO handle properly when CLONE_DIR exists but is not an directory
        echo "not a directory ${CLONE_DIR}"
        exit 1;
    else
        # @TODO check if we have clone wchich should be pulled
        # right now only pull
        #set -xve
        echo "Pull directory"
        (git --git-dir=${CLONE_DIR}/.git fetch origin &>/dev/null && git --git-dir=${CLONE_DIR}/.git --work-tree=${CLONE_DIR} pull origin master &>/dev/null) \
            || { echo "Pull failed" >&2; exit 1; }
        #set +xve
    fi
    (cd ${PROJECTS}/${my_pkg} && autoconf && automake) || { echo "Configuration failed" >&2; exit 1; }
}

function fetch_svn() {
    echo "Fetch SVN repository"
}

function fetch_bzr() {
    echo "Bazaar not supported yet"
    exit 1
}

function fetch_hg() {
    echo "Mercurial not supported yet"
    exit 1
}

function fetch_repository() {
    echo "Fetch source from repository"
    if [[ -n "${REPOSITORY_GIT:-}" ]]; then
        fetch_git
    elif [[ -n "${REPOSITORY_SVN:-}" ]]; then
        fetch_svn
    elif [[ -n "${REPOSITORY_BZR:-}" ]]; then
        fetch_bzr
    elif [[ -n "${REPOSITORY_HG:-}" ]]; then
        fetch_hg
    else
        echo "Repository not configured"
        exit 1
    fi
}

function verify_sha1() {
    echo "Verifying SHA1"
}

function verify_md5() {
    echo "Verifying MD5"
}

function verify_sha256() {
    echo "Verifying SHA256"
}

function verify() {
    if [[ -n "${CHECKSUM_SHA1:-}" ]]; then
        verify_sha1
    fi
    if [[ -n "${CHECKSUM_MD5:-}" ]]; then
        verify_md5
    fi
    if [[ -n "${CHECKSUM_SHA256:-}" ]]; then
        verify_sha256
    fi
}

function fetch_pkg() {
    if [ ${PACKAGE} ]; then
        if [[ -z $SKIP_DOWNLOAD ]]; then
            echo "Downloading package (${PACKAGE})"
            rm -rf ${PROJECTS}/${PACKAGE}
            curl ${http_proxy:+-x $http_proxy} -# -k -L -O ${PKG_URI}/${PACKAGE}
            DOWNLOADED=$?
        else
            echo "Skipping download" >&2
            DOWNLOADED=0
        fi
    else
        echo "Package not given"
        exit 1
    fi

    if [[ $DOWNLOADED -eq 0 ]]; then
        rm -rf ${CLONE_DIR}
        mkdir -p ${CLONE_DIR}
       	unpack -f ${PROJECTS}/${PACKAGE} -C ${CLONE_DIR} -s 1
    else
        exit ${DOWNLOADED}
    fi
}

function fetch() {
    if [[ -n "${USE_CHECKOUT:-}" ]]; then
        fetch_repository
    else
        fetch_pkg
    fi
}

function configure_autoconf() {
    (
        cd ${PROJECTS}/${my_pkg}
        [ -d ${BUILD_DIR} ] || { echo "Creating build directory: ${BUILD_DIR}"; mkdir -p ${BUILD_DIR}; }
        cd ${BUILD_DIR} && PKG_CONFIG_PATH=${TOOLSPATH}/lib/pkgconfig ${CLONE_DIR}/configure ${CONFIGURE_OPTS:+$CONFIGURE_OPTS} --prefix=${INSTALL_ROOT}/${my_pkg}-${PKG_VERSION}-${SYSTEM_RELEASE}-${HOSTTYPE}
        make
        make install
    )
}

function configure_scons() {
    echo "Configure using scons tool"
}

function configure_cmake() {
    echo "Configure using cmake"
}

function configure() {
    configure_autoconf
}


################################
# MAIN code for install script #
################################

fetch
configure

exit 0
