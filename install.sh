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
BUILD_DIR=${BUILD_DIR:-"${PROJECTS}/${my_name}-build"}

source $my_dir/ports-config.sh
CONFIG=$my_dir/$(basename ${BASH_SOURCE[0]} .sh).rc
if [ -e ${CONFIG} ]; then
    source ${CONFIG}
fi

function unpack() {
	echo "Unpack" >&2
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
		tar xJf $file ${path:+-C $path} ${strip_components:+--strip-components=$strip_components}
	else
		echo "WTF $file" >&2
	fi
}

USE_CHECKOUT=
while getopts ":p:c" opt; do
    case $opt in
        p)
            PACKAGE=$OPTARG
            ;;
        c)
            USE_CHECKOUT=Y
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        esac
done
OPTIND=0;

DOWNLOADED=0
if [[ -n $USE_CHECKOUT ]]; then
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
        #set -xve
        echo "Pull directory"
        (git --git-dir=${CLONE_DIR}/.git fetch origin &>/dev/null && git --git-dir=${CLONE_DIR}/.git --work-tree=${CLONE_DIR} pull origin master &>/dev/null) \
            || { echo "Pull failed" >&2; exit 1; }
        #set +xve
    fi
    (cd ${PROJECTS}/${my_pkg} && autoconf && automake) || { echo "Configuration failed" >&2; exit 1; }
else
    if [ ${PACKAGE} ]; then
        echo "Downloading package (${PACKAGE})"
        rm -rf ${PROJECTS}/${PACKAGE}
	set -vx
        curl ${http_proxy:+-x $http_proxy} -# -k -L -O ${PKG_URI}/${PACKAGE}
	set +vx
        DOWNLOADED=$?
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
fi

(
    cd ${PROJECTS}/${my_pkg}
    [ -d ${BUILD_DIR} ] || { mkdir -p ${BUILD_DIR}; }
    cd ${BUILD_DIR}
    PKG_CONFIG_PATH="${TOOLSPATH}/lib/pkgconfig" ${CLONE_DIR}/configure --prefix=${INSTALL_ROOT}/${my_pkg}-${PKG_VERSION}-${SYSTEM_RELEASE}-${HOSTTYPE}
    make
    make install
)

exit 0
