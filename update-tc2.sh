#make ARCH=arm vexpress_defconfig
#ARCH=arm scripts/kconfig/merge_config.sh linaro/configs/linaro-base.conf linaro/configs/android.conf linaro/configs/big-LITTLE-MP.conf linaro/configs/big-LITTLE-IKS.conf linaro/configs/vexpress.conf

make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j 16 zImage && \
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- vexpress-v2p-ca15_a7.dtb && \
#cat arch/arm/boot/dts/vexpress-v2p-ca15_a7.dtb >> arch/arm/boot/zImage && \
mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000 -n 'Ubuntu Kernel' -d arch/arm/boot/zImage /tftpboot/u-zimage.bin && scp /tftpboot/u-zimage.bin hackbox.val: &&
scp arch/arm/boot/dts/vexpress-v2p-ca15_a7.dtb hackbox.val:u-dtb.bin


## update u-image # after power reset
# alex-shi@hackbox:~$ sudo mount /dev/sdd1 /media/hackbox2  # sdx show in dmesg
# alex-shi@hackbox:~$ cp tc2-uImage /media/hackbox2/SOFTWARE/TC2/
#
## power reset tc2
# /usr/local/lab-scripts/pduclient --daemon services --hostname pdu09 --command reboot --port 03
# Cmd> reboot
## ... reprogramm u-image
# >fl source ubuntu
#
# ssh hackbox.val
# telnet serial4 7003 or ssh mphackbox

# https://wiki.linaro.org/Platform/LAVA/DevOps/TC2TilesOnLavaServer/hackbox
# fl linux boot kern_mp androidboot.hardware=arm-versatileexpress-usb console=ttyAMA0,38400n8 root=/dev/sda2 rootwait mmci.fmax=4000000
