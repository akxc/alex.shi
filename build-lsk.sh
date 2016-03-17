#!/bin/bash
#
#This script can be wrapped for full coverage LSK testing, like
#for i in arm arm64; do
#	for j in linux-linaro-lsk linux-linaro-lsk-android linux-linaro-lsk-rt; do
#		./$0 $j $i def;
#	done
#done
#
#or build random config:
#for ((i=0;i<10;i++)); do
#	./$0 linux-linaro-lsk arm random || break;
#done

nr_cpu=`cat /proc/cpuinfo| grep "^processor"| wc -l`

#make kernel config and do kernel build
build() {
	local errconfig=${ARCH}-${branch}-${config}-err;
	local errlog=${errconfig}-log

	if ! eval $do_config;then
		echo "make config failed !!!"
		return 1
	fi


	target=Image
	grep -q "CONFIG_MODULES=y" .config && target="modules Image"

	if make -j $nr_cpu $target > /dev/null 2> $errlog; then
		echo "... built well on ${ARCH}"
		return 0
	else
		echo "... built failed on ${ARCH} !!!"
		cp .config $errconfig
		cat $errlog
		return 1
	fi
}

#------------ running from here ------------#
usages="./$0 linux-linaro-lsk arm/arm64 def/linaro/random"

branch=$1
version=$2
config=$3

if [ "$version" == 'arm64' ];then
	export ARCH=arm64 
	export CROSS_COMPILE=aarch64-linux-gnu-
	export LINARO_CONFIG="vexpress64.conf"
else
	export ARCH=arm 
	export CROSS_COMPILE=arm-linux-gnueabihf-
	export LINARO_CONFIG="vexpress.conf"
fi

#try to include as much as possible configure options
linaro_config="scripts/kconfig/merge_config.sh linaro/configs/linaro-base.conf \
	linaro/configs/distribution.conf linaro/configs/kvm-guest.conf linaro/configs/kvm-host.conf \
	linaro/configs/debug.conf linaro/configs/big-LITTLE-MP.conf linaro/configs/xen.conf \
	linaro/configs/big-LITTLE-IKS.conf linaro/configs/$LINARO_CONFIG"

if [ "$config" == 'linaro' ];then
	do_config="$linaro_config"
elif [ "$config" == 'random' ];then
	do_config="make randconfig"
else
	do_config="make defconfig"
fi

echo "git checkout $branch ..."
if git checkout $branch; then
	echo "done"
	echo "Build $branch $version $config config starting ..."
	build $version
else
	echo "checkout $branch failed !!!"
	exit 1
fi

