#ARCH=arm ./scripts/kconfig/merge_config.sh linaro/configs/linaro-base.conf linaro/configs/distribution.conf linaro/configs/vexpress.conf &&
make ARCH=arm vexpress_defconfig &&
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j 16 zImage 
#make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- 
