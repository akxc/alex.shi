make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CONFIG_DEBUG_SECTION_MISMATCH=y defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j16 Image.gz rtsm_ve-aemv8a.dtb

#make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- BOOTARGS='"root=/dev/vda2 consolelog=9 rw console=ttyAMA0"' FDT_SRC=vexpress-foundation-v8.dts IMAGE=linux-system-foundation.axf

#kernel config file

ARCH=arm64 scripts/kconfig/merge_config.sh \
linaro/configs/linaro-base.conf \
linaro/configs/linaro-base64.conf \
linaro/configs/distribution.conf \
linaro/configs/vexpress64.conf \
linaro/configs/kvm-host.conf \
linaro/configs/kvm-guest.conf
