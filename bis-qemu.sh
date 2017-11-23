#!/bin/bash

kernelsource=/mmkernels/kernel
#qemusource=/home/alexs/boards/qemu
# check the redir port to guest, always good if qemu booted, not guest booted
#nmap -p $mapp 127.0.0.1 | grep $mapp | grep open 
mapp=5555

qemucmd="qemu-system-aarch64 -M virt -cpu cortex-a57 -m 512 -kernel /mmkernels/kernel/arch/arm64/boot/Image -append 'earlycon console=ttyAMA0' -bios /home/alexs/boards/qemu/QEMU_EFI.fd.KASLR -redir tcp:$mapp::22 -daemonize  -serial file:qemu.log && sleep 5"

function buildkernel () {
	cd $kernelsource
	#make ARCH=arm64 defconfig
	scripts/config -e CONFIG_RANDOMIZE_BASE
	#make -s ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j 16
	#scripts/config --set-str CONFIG_INITRAMFS_SOURCE /home/alexs/boards/buildroot.git/output/images/rootfs.cpio
	#make -s ARCH=arm64 olddefconfig && make -s ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j 16
	make -s ARCH=arm64 olddefconfig &&
	make -s ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j 16
}

function runqemu() {
	eval $qemucmd
	grep "NET: Registered protocol family" qemu.log
}

if buildkernel ; then
	runqemu
	ret=$?
	killall  qemu-system-aarch64
	exit $ret
else
	echo "Build failed"
	exit 1
fi

