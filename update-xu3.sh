
if [ "$1" != "" ]; then 
	ARCH=arm make exynos_defconfig
fi

#LOADADDR=0x80008000 make ARCH=arm CROSS_COMPILE=arm-unknown-linux-gnueabi- -j 8 modules uImage && 
ARCH=arm CROSS_COMPILE=arm-unknown-linux-gnueabi- make -j 8  zImage && 
ARCH=arm CROSS_COMPILE=arm-unknown-linux-gnueabi- make  exynos5422-odroidxu3.dtb && 
cat arch/arm/boot/dts/exynos5422-odroidxu3.dtb >> arch/arm/boot/zImage && 
mkimage -A arm -O linux -T kernel -C none -a 0x40008000 -e 0x40008000 -n 'Ubuntu Kernel' -d arch/arm/boot/zImage /tftpboot/xu3-zImage
cp arch/arm/boot/zImage	/tftpboot/xu3-zImage

