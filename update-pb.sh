if true; then
#ARCH=arm scripts/kconfig/merge_config.sh linaro/configs/linaro-base.conf linaro/configs/distribution.conf linaro/configs/omap4.conf linaro/configs/preempt-rt.conf
#ARCH=arm scripts/kconfig/merge_config.sh linaro/configs/linaro-base.conf linaro/configs/distribution.conf linaro/configs/omap4.conf linaro/configs/bigendian.conf

if grep 'PATCHLEVEL = 14' Makefile; then 
	#cp cpuidle-usb-panda-config .config
	:
else
	#ARCH=arm scripts/kconfig/merge_config.sh linaro/configs/linaro-base.conf linaro/configs/distribution.conf linaro/configs/omap4.conf
	:
fi

#make ARCH=arm omap2plus_defconfig

#LOADADDR=0x80008000 make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j 8 modules uImage && 
#LOADADDR=0x80008000 make ARCH=arm CROSS_COMPILE=arm-unknown-linux-gnueabi- -j 8 modules uImage && 
ARCH=arm CROSS_COMPILE=arm-unknown-linux-gnueabi- make -j 8  zImage && 
ARCH=arm CROSS_COMPILE=arm-unknown-linux-gnueabi- make  omap4-panda-es.dtb && 
#make ARCH=arm modules_install INSTALL_MOD_PATH=~/boards/pandaboard/initrd/ &&
cat arch/arm/boot/dts/omap4-panda-es.dtb >> arch/arm/boot/zImage && 
cp arch/arm/boot/dts/omap4-panda-es.dtb /tftpboot/	&&
mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n 'Ubuntu Kernel' -d arch/arm/boot/zImage /tftpboot/zImage
#cp arch/arm/boot/zImage	/tftpboot/zImage

#install modules to panda board
#rsync -av ~/boards/pandaboard/initrd/lib/modules/ root@panda:/lib/modules/

fi


