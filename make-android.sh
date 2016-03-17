#make ARCH=arm vexpress_defconfig
scripts/kconfig/merge_config.sh -m linaro/configs/linaro-base.conf linaro/configs/android.conf linaro/configs/big-LITTLE-MP.conf linaro/configs/vexpress.conf linaro/configs/big-LITTLE-IKS.conf linaro/configs/vexpress-tuning.conf android/configs/android-base.cfg ../../../device/linaro/vexpress/android-quirks.conf
make ARCH=arm alldefconfig
make ARCH=arm CROSS_COMPILE=arm-linux-androideabi- -j 16 vmlinux 
