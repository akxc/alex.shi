echo -e "\nmake arm64 defconfig vmlinux\n" &&
make -s ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j 8 defconfig vmlinux &&
make ARCH=arm64 clean; echo -e "\nmake multi_v7_defconfig vmlinux\n" &&
#ARCH=arm CROSS_COMPILE=arm-unknown-linux-gnueabi- make -j 8  multi_v7_defconfig vmlinux -s &&
ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- make -j 8  multi_v7_defconfig vmlinux -s &&
make ARCH=arm clean; echo -e "\nmake x86 defconfig vmlinux\n" &&
make -s -j 8 defconfig vmlinux &&
make clean; echo -e "\n FINISHED all make testing!\n"

