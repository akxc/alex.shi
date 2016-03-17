#!/bin/sh
UEFI=/opt/workspace/boot/uefi/edk2/Build/ArmVirtualizationQemu-AARCH64/DEBUG_GCC48/FV/QEMU_EFI.fd
# Invoke UEFI without persistent variables
#./aarch64-softmmu/qemu-system-aarch64 -m 1024 -cpu cortex-a57 -M virt -bios $UEFI -serial stdio
# Invoke UEFI with persistent variables
case $1 in
1)
	cat $UEFI /dev/zero | dd iflag=fullblock bs=1M count=64 of=flash0.img
	dd if=/dev/zero of=flash1.img bs=1M count=64
	;;
2)
	./aarch64-softmmu/qemu-system-aarch64 -m 1024 -cpu cortex-a57 -M virt -pflash flash0.img -pflash flash1.img -serial stdio
	;;
esac
