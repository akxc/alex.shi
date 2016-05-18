#!/bin/bash
#
# Alex Shi <alex.shi@linaro.org>
#
# Dependence:
# 1, board's u-boot auto-fetch the uImage from server:/tftpboot/ after reboot
# 2, ssh no-key setup between server and board system
# 3, board named as same as board type
# 4, need hardware reset support on board ---- todo
# 5, serial console log at server:${seriallog[$board]}
# 6, check func regression need 'check_func' script, user@board:./check_func 

# TODO,
#     1, use a power switc to do hardware reset of board
#     2, use conmux to interactive with serial port

build_base='make ARCH=arm olddefconfig && \
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j 16 '
build_zImage="$build_base zImage > /dev/null"
build_all="$build_base all"

typeset -A config mk_uImage seriallog
#replace your specific kernel config here.
#config[panda]='ARCH=arm scripts/kconfig/merge_config.sh linaro/configs/linaro-base.conf \
#			linaro/configs/distribution.conf linaro/configs/omap4.conf' 
config[panda]='cp config-nohz_full_all .config'

#macro for making uImage for specific board
mk_uImage[panda]="$build_zImage && \
	make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- omap4-panda-es.dtb && \
	cat arch/arm/boot/dts/omap4-panda-es.dtb >> arch/arm/boot/zImage    && \
	mkimage -A arm -O linux -T kernel -C none -a 0x80008000 -e 0x80008000  \
	    -n 'Ubuntu Kernel' -d arch/arm/boot/zImage /tftpboot/zImage"
seriallog[panda]=~/serial-console/seriallog_panda

check_parameters(){
	if [ -z "$lgood" -o -z "$fbad" ];then
		print_usage
		exit 1
	fi

	if ! git show $lgood $fbad > /dev/null; then
		echo "Can not find commit $lgood or $fbad, please check again!"
		exit 1
	fi

	# set default board and bisect type
	[ -z "$board" ] && board=panda
	[ -z "$bistype" ] && bistype=build
}

#assemble git bisect run script, after testing, the script will be removed
make_script(){

cat > $bisect_script <<EOF
#!/bin/bash

#git bisect skip this commit if build failed
$build_zImage || exit 125
EOF

	if [ "$bistype" != "build" ]; then
cat >> $bisect_script <<EOF

logfile=${seriallog[$board]}
bquota=50
reboottime=0

ck_boot_manual(){
	echo Maybe failure due to network access issue, really boot failure?
	while read failed; do
		case "\$failed" in
		y)	echo "boot failed"; exit 1 ;;
		n)	echo "fake warning, network issue"; exit 0 ;;
		*)	echo "incorrect input, y/n" ;;
		esac
	done

}

check_boot(){
	${config[$board]} && ${mk_uImage[$board]} || exit 125

	# $board reperents the host name of board
	# Iff software reboot failed, press reset button board by hands.
	# need hardware utils support for auto power reset. ---- !!!
	if ! ssh $board sudo reboot; then
		echo "pressed reset button to force board to load uImage? y/n"
		while read pressed; do
			[ "\$pressed" = 'y' ] && break
			[ "\$pressed" = 'n' ] && echo "please press reset button on board" 
		done
	fi		
	sleep 10 #wait board reboot and load uImage, extend the time if needed 

	while (! ssh $board echo connected) && ((reboottime < bquota))
	do
		((reboottime++))
		sleep 1
	done

	#reconnected after board reset, good!
	((reboottime < bquota)) && return 0

	#ssh connection failed
	if [ "$bistype" = "boot" ];then
		if [ -f \$logfile ];then
			# or is 'VFS: Mounted root' better?
			tail -30 \$logfile | grep 'login' && exit 0
			exit 1
		else
			ck_boot_manual
		fi
	fi
	return 1
}

check_boot
EOF
	fi

	if [ "$bistype" = "func" ]; then
cat >> $bisect_script <<EOF

do_func_checking(){
	if ((reboottime < bquota));then
		echo -e "\\t ************** auto-check func *************"
		ssh $board ./check_func
		exit \$?
	fi
	#skip this commit if boot failed.
	[ -z \$logfile ] && tail -30 \$logfile | grep -v 'login' && exit 125

	echo "need manual check, func well? y/n"
	while read result; do
		case "\$result" in
		y)	echo "func success"; exit 0   ;;
		n)	echo "func failed"; exit 1   ;;
		*)	echo "incorrect input, func well? y/n" ;;
		esac
	done
}

do_func_checking
EOF
	fi

chmod u+x $bisect_script
}

print_usage(){
cat <<EOF
This script bisects kernel for build/boot/func regressions on 
appointed board, run it in kernel source tree.
It can create a \$bisect_script in kernel source for boot/func test.

If kernel friendly for network, it is a fully automatic bisect
script, otherwise it is a semi-automatical scripts.

$./bisect.sh -g v3.11~2 -b v3.11 -t func 2>&1 | tee func.log
Usage:
	-g good commit ID, like HEAD, v3.12-rc7
	-b bad commit ID, like v3.11
	-s bisect scope in kernel tree
	-B specific board for specific kernel config
	-t bisection type
		build: bisect kernel build
		boot:  bisect board booting
		func:  bisect for function regression
		       in system. To run a script in board system, then 
		       judge the kernel bisect direction according to 
		       script's return value.
EOF
        exit 1;
}

#------------ script start from here -------------
while getopts g:b:t:s:B:h opt
do case "$opt" in
	g)	lgood=$OPTARG ;;
	b)	fbad=$OPTARG ;;
	t)	bistype=$OPTARG ;;
	s)	scope=$OPTARG ;;
	B)	board=$OPTARG ;;
	-h|*)      print_usage ;;
esac
done

check_parameters 

bisect_script=${bistype}_${board}_$(date +%s)
#exec >${bisect_script}.log 2>&1
echo $(date)

make ARCH=arm mrproper && git bisect reset
git bisect start $fbad $lgood -- $scope

#try making config
if ! ${config[$board]} ;then
	echo "Can not make kernel config:\"${config[$board]}\"!"
	exit 1
fi

#run bisect 
case "$bistype" in
	build)
		git bisect run bash -c "${config[$board]} && $build_all"
		;;
	boot | func)
		make_script
		git bisect run ./$bisect_script
		#rm $bisect_script
		;;
	*)
		echo "Wrong bisection type!" ;;
esac
git bisect log 
