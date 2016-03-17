#!/bin/bash
# Author+=amit.pundir@linaro.org

set -e

EXACT=1
INTERACTIVE=1
DIR=android
if [ -z "${LINARO_ANDROID_ACCESS_ID}" ] ; then
	LINARO_ANDROID_ACCESS_ID=default-bot
fi
SOURCE_OVERLAY_OPTIONAL=1

usage()
{
	echo 'Usage: $0 -m <manifest.xml> -o <overlay.tar> [ -t -d directory -l login ]'
	echo -e '\n -m <manifest>    If -t is not used, then using a browser with cookies you\n                  must download the pinned manifest from:\n             http://snapshots.linaro.org/android/~linaro-android-restricted/vexpress-linaro-lsk/88/\n -o               The path to the vendor required overlay.\n                  Can be downloaded from http://snapshots.linaro.org/android/binaries/big-little-switcher-private/20121218/build-info.tar.bz2\n'
	echo " -t                Reproduce the build from the tip of the branch rather than doing"
	echo "                   an exact replica build"
	echo " -d <directory>    The directory to download code and build from"
	echo "                   Default: ${DIR}"
	echo " -l <login-id>     login-id to clone from linaro-private git repositories"
	echo "                   If in doubt, please contact Linaro Android mailing list for details"
	echo "                   Default: ${LINARO_ANDROID_ACCESS_ID}"
	echo " -y                Assume answer 'YES' for all questions. Non-interactive mode. Requires -l"
	exit 1
}

while getopts   "m:o:d:l:hty" optn; do
	case    $optn   in
		o   ) SOURCE_OVERLAY=$OPTARG; SOURCE_OVERLAY_OPTIONAL=0;;  m   ) MANIFEST=`readlink -f $OPTARG`;;
		d   ) DIR=$OPTARG;;
		l   ) LINARO_ANDROID_ACCESS_ID=$OPTARG;;
		t   ) EXACT=0;;
		y   ) INTERACTIVE=0;;
		h   ) usage; exit 1;;
        esac
done

if [ "${LINARO_ANDROID_ACCESS_ID}" == "default-bot" -a ${INTERACTIVE} -eq 0 ] ; then
    usage
fi

UBUNTU=`cat /etc/issue.net | cut -d' ' -f2`
HOST_ARCH=`uname -m`
if [ ${HOST_ARCH} == "x86_64" ] ; then
	PKGS='gnupg flex bison gperf build-essential zip curl zlib1g-dev libc6-dev lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev g++-multilib mingw32 tofrodos python-markdown libxml2-utils xsltproc uboot-mkimage openjdk-6-jdk openjdk-6-jre vim-common python-parted python-yaml wget'
else
	echo "ERROR: Only 64bit Host(Build) machines are supported at the moment."
	exit 1
fi
if [[ ${UBUNTU} =~ "13." || ${UBUNTU} =~ "12.10" ]]; then
	#Install basic dev package missing in chrooted environments
	sudo apt-get install software-properties-common
	sudo dpkg --add-architecture i386
	PKGS+=' libstdc++6:i386 git-core'
elif [[ ${UBUNTU} =~ "12.04" || ${UBUNTU} =~ "10.04" ]] ; then
	#Install basic dev package missing in chrooted environments
	sudo apt-get install python-software-properties
	if [[ ${UBUNTU} =~ "12.04" ]]; then
		PKGS+=' libstdc++6:i386 git-core'
	else
		PKGS+=' ia32-libs libssl-dev libcurl4-gnutls-dev libexpat1-dev gettext'
	fi
else
	echo "ERROR: Only Ubuntu 10.04, 12.* and 13.04 versions are supported."
	exit 1
fi

echo
echo "Setting up Ubuntu software repositories..."
sudo add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe restricted multiverse"
sudo apt-get update
echo
echo "Installing missing dependencies if any..."
if [ $INTERACTIVE -eq 1 ] ; then
	sudo apt-get install ${PKGS}
else
	sudo apt-get -y install ${PKGS}
fi
# Obsolete git version 1.7.04 in lucid official repositories
# repo need at least git v1.7.2
if [[ ${UBUNTU} =~ "10.04" ]]; then
	echo
	echo "repo tool complains of obsolete git version 1.7.04 in lucid official repositories"
	echo "Building git for lucid from precise sources .."
	wget http://archive.ubuntu.com/ubuntu/pool/main/g/git/git_1.7.9.5.orig.tar.gz
	tar xzf git_1.7.9.5.orig.tar.gz
	cd git-1.7.9.5/
	make prefix=/usr
	sudo make prefix=/usr install
fi

if [ $EXACT -eq 1 ]; then
	if [ "a$MANIFEST" == "a" -o ! -f $MANIFEST ]; then
		echo "ERROR: no pinned manifest provided. Please download from http://snapshots.linaro.org/android/~linaro-android-restricted/vexpress-linaro-lsk/88/. This must be done from a browser that accepts cookies."
		exit 1
	fi
fi
if [ $SOURCE_OVERLAY_OPTIONAL -ne 1 ]; then
	if [ "a$SOURCE_OVERLAY" == "a" -o ! -f $SOURCE_OVERLAY ]; then
		echo "ERROR: no source overlay provided. Please download from http://snapshots.linaro.org/android/binaries/big-little-switcher-private/20121218/build-info.tar.bz2. This must be done from a browser that accepts cookies."
		exit 1
	fi
fi
if [ -d ${DIR} ] ; then
	if [ $INTERACTIVE -eq 1 ] ; then
		echo "Directory ${DIR} exists. Are you sure you want to use this? (y/n) "
		read CONTINUE
		[ ${CONTINUE} == y ] || exit 1
	else
		echo "Using existing directory: ${DIR} . "
	fi
else
	mkdir ${DIR}
fi
cd ${DIR}

# check for linaro private manifests
PM=`echo git://android.git.linaro.org/platform/manifest.git | grep -i "linaro-private" | wc -l`
if [ ${PM} -gt 0 -a ${INTERACTIVE} -eq 1 ] ; then
	if [ "${LINARO_ANDROID_ACCESS_ID}" == "default-bot" ] ; then
		echo "You must specify valid login/access-id to clone from linaro-private manifest repositories."
		echo "Press "y" to continue (which may result in incomplete build or failure), OR"
		echo "Press "n" to enter login details, OR"
		echo "Press "h" for help."
		read NEXT
		if [ ${NEXT} == n ] ; then
			echo "Enter login/access-id:"
			read LINARO_ANDROID_ACCESS_ID
		elif [ ${NEXT} == h ] ; then
			usage
		fi
	fi
fi
export MANIFEST_REPO=`echo git://android.git.linaro.org/platform/manifest.git | sed 's/\/\/.*-bot@/\/\/'"${LINARO_ANDROID_ACCESS_ID}"'@/'`
export MANIFEST_BRANCH=linaro_android_4.2.2
export MANIFEST_FILENAME=default.xml
export TARGET_PRODUCT=vexpress
export TARGET_SIMULATOR=false
export BUILD_TINY_ANDROID=
export CPUS=`grep -c processor /proc/cpuinfo`
export INCLUDE_PERF=
export TARGET_BUILD_VARIANT=
export BUILD_FS_IMAGE=
export DEBUG_NO_STRICT_ALIASING=
export DEBUG_NO_STDCXX11=
export TOOLCHAIN_TRIPLET=arm-linux-androideabi
export ANDROID_64=
export TARGET_TOOLS_PREFIX=prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.7-linaro/bin/arm-linux-androideabi-

# download the repo tool for android
curl "http://android.git.linaro.org/gitweb?p=tools/repo.git;a=blob_plain;f=repo;hb=refs/heads/stable" > repo
chmod +x repo

# download the android code
./repo init -u ${MANIFEST_REPO} -b ${MANIFEST_BRANCH} -m ${MANIFEST_FILENAME} --repo-url=git://android.git.linaro.org/tools/repo -g common,vexpress-lsk,vexpress-tests
if [ ${EXACT} -eq 1 ] ; then
	rm .repo/manifest.xml
	cp $MANIFEST .repo/manifest.xml
fi
# check for linaro private git repositories
PRI=`grep -i "linaro-private" .repo/manifests/${MANIFEST_FILENAME} | wc -l`
if [ ${PRI} -gt 0 -a ${INTERACTIVE} -eq 1 ] ; then
	if [ "${LINARO_ANDROID_ACCESS_ID}" == "default-bot" ] ; then
		echo "You must specify valid login/access-id to clone from linaro-private git repositories."
		echo "Press "y" to continue (which may result in incomplete build), OR"
		echo "Press "n" to enter login details, OR"
		echo "Press "h" for help."
		read NEXT
		if [ ${NEXT} == n ] ; then
			echo "Enter login/access-id:"
			read LINARO_ANDROID_ACCESS_ID
		elif [ ${NEXT} == h ] ; then
			usage
		fi
	fi
	sed -i 's/\/\/.*-bot@/\/\/'"${LINARO_ANDROID_ACCESS_ID}"'@/' .repo/manifests/${MANIFEST_FILENAME}
fi
./repo sync -f -j1


if [ $SOURCE_OVERLAY_OPTIONAL -ne 1 ]; then
	# extract the vendor's source overlay
	tar -x -a -f "$SOURCE_OVERLAY" -C .
fi

# build the code
. build/envsetup.sh
make -j${CPUS} boottarball systemtarball userdatatarball
