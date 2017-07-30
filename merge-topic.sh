#!/bin/bash
#
# This script is a engineering tool for lsk branches
# merge and push work. If conflict happends, this tool will stop.
#
# Request: 
#	The working git tree either doesn't check out LSK branches,
# 	or all of lsk branches are checked out with the origin's branch name.
#	
#	remote LTS tree linked as 'lts'; LSK linked as 'origin'


print_usage(){
cat <<EOF
usage example: 	#to merge&push a feature branch to 3.10 lsk-x-test branches
		./$0 3.10 origin/v3.10/topic/feature

		#to merge&push lts/linux-3.14.y to lsk 3.14 branches
		./$0 3.14
EOF
}

# Return 0 if there is an exclusive commit on $TARGET from LSK base;
# otherwise return 1;
need_merge(){
	local lastci=$(git rev-list --max-count=1 $mergee)

	[ -z "$lastci" ] && return 1

	local found=`git branch -r --contains $lastci origin/$merger`

        [ -z "$found" ] && return 0

	echo "### $mergee merged into $merger already!"
	return 1
}

# Hardcode branches' names
get_br_name() {
	lsk[base]=linux-linaro-lsk-v$VER
	lsk[android]=linux-linaro-lsk-v"$VER"-android
	lsk[rt]=linux-linaro-lsk-v"$VER"-rt
}

# Prepare a clean local branch before topic merging
check_merger() {
	local merger="$1"
	echo "# git checking out $merger"
	git checkout $merger || return 1
	git pull || return 1

	local gdiff=`git log --oneline origin/$merger...HEAD`
	if [ -n "$gdiff" ]; then
		echo " # local branch isn't sync with remote branch origin/$merger"
		return 1
	fi
	return 0
}

build_testing() {

	# only merge LTS and no merge error, so ...
	[ $NOTESTING -eq 1 -o "$NOTESTING" = "no" ] && return 0

	pushd $PWD;
	if cd $GIT_WORK_TREE &&
		echo -e "\nmake arm64 defconfig vmlinux\n" &&
		make -s ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j 8 defconfig vmlinux &&
		echo -e "\nmake multi_v7_defconfig vmlinux\n" &&
		ARCH=arm CROSS_COMPILE=arm-unknown-linux-gnueabi- make -s -j 8  multi_v7_defconfig vmlinux &&
		echo -e "\nmake x86 defconfig vmlinux\n" &&
		make -s -j 8 defconfig vmlinux ; then
			popd
			return 0
	fi
	popd
	return 1
}

# Merge $TARGET branch and push to offical LSK
do_merge_push() {

	declare -A lsk merged
	get_br_name

	# no TARGET input, means to merge lts branch
	if [ -z "$TARGET" ] ;then
		#don't need test if only merge LTS
		NOTESTING=1
		TARGET="lts/linux-${VER}.y"
		# subver like '3.10.51'
		subver=`git log $TARGET -1 | grep Linux | awk '{print $2}'`
	fi

	# Do merging
	mergee=$TARGET
	for x in base android rt; do
		#we only merge $TARGET to base lsk, and then merge base lsk to others
		merger=${lsk[$x]}
		[ $x != 'base' ] && mergee=${lsk[base]}

		#don't rt kernel except 4.9 version
		#we get patch from rt 4.9 version instead of LTS
		if [ $VER == '4.9' -a $x == 'rt' ];then
			mergee="rt/linux-${VER}.y-rt"
		elif [ $x == 'rt' ]; then
			continue
		fi

		if ! need_merge; then
			[ $x == 'base' ] && break
			continue
		fi

		#only written merge message for lts to base lsk branch.
		if [ -n "$subver" -a $x == 'base' ];then
		message="Merge tag 'v$subver' into ${lsk[base]} \n\n This is the $subver stable release"
			mp="-m $(echo -e $message)"
		else
			mp="--no-edit"
		fi

		echo "### local branch preparation"
		if ! check_merger $merger; then
			echo "Failed merging on $merger: commit different !!!" |
				mutt -s "merge failed on $mergee to $merger in $GIT_DIR" $monitor
			[ $x == 'base' ] && break
			continue
		fi

		#Do merge
		if ! git merge $mergee "$mp"; then
			 git diff |
				mutt -s "merge failed on $mergee to $merger in $GIT_DIR" $monitor

			# clean up the dirty work tree for next kernel merge
			git merge --abort
			#try rt if merge failed on android
			[ $x == 'base' ] && break
			continue
		fi

		#Run build testing
		if ! build_testing &> /tmp/build.log ; then
			cat /tmp/build.log |
				mutt -s "build failed on $mergee to $merger in $GIT_DIR" $monitor
			#try rt if merge failed on android
			[ $x == 'base' ] && break
			continue
		fi

		# Set remote push branch: remote_br
		# feature only can merge to remote -test branch !!!
		[ "$TARGET" == "lts/linux-${VER}.y" ] && remote_br=${lsk[$x]}
		[ "$TARGET" != "lts/linux-${VER}.y" ] &&	remote_br=${lsk[$x]}-test
		PUSHB="$PUSHB ${lsk[$x]}:$remote_br"

		echo "merge and build test done on $mergee to $merger in $GIT_DIR"
	done

	# Do push
	if [ -n "$PUSHB" ]; then
		if git push origin $PUSHB &> /tmp/push.log; then
			echo "Pushed $PUSHB" | mutt -s "merged and pushed $GIT_DIR" $monitor
		else
			cat /tmp/push.log | mutt -s "push failed $PUSHB in $GIT_DIR" $monitor
		fi
	fi

	
}

# ----------------------- work start ---------------------------#

#Get VER and TARGET from input
VER=$1
TARGET=$2
NOTESTING=$3

if [ -z "$GIT_WORK_TREE" -o -z "$GIT_DIR" -o -z "$monitor" ]; then
	echo "one of ENV value null, please check"
	echo GIT_WORK_TREE=$GIT_WORK_TREE
	echo GIT_DIR=$GIT_DIR
	echo monitor=$monitor
	exit 1
fi

#Only support current LSK version
if [ "$VER" != '4.9' -a "$VER" != '3.18' -a "$VER" != '4.4' ]; then
	print_usage;
	exit 1
fi

do_merge_push $VER $TARGET

