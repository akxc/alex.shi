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

# Return 0 if there is an exclusive commit on $TOPIC from LSK base;
# otherwise return 1;
need_merge(){
	local lastci=$(git rev-list --max-count=1 $TOPIC)

	[ -z "$lastci" ] && return 1

	local found=`git branch -r --contains $lastci origin/${lsk[base]}`

        [ -z "$found" ] && return 0

	echo "### $TOPIC merged into LSK already!"
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

# Merge $TOPIC branch and push to offical LSK 
do_merge_push() {

	declare -A lsk merged
	get_br_name

	# no TOPIC input, means to merge lts branch
	if [ -z "$TOPIC" ] ;then
		#don't need test if only merge LTS
		NOTESTING=1
		TOPIC="lts/linux-${VER}.y"
		# subver like '3.10.51'
		subver=`git log $TOPIC -1 | grep Linux | awk '{print $2}'`
	fi

	if ! need_merge;then
		return 0;
	fi

	# Do merging
	# Since rt is maintained by Anders Roxell, and it is easy to have conflict during merging
	# it is better to left the job to Ander.
	# The rt branch wasn't released often, the branch looks a bit out of date, so start regular
	# rt by ourself.
	mergee=$TOPIC
	for x in base android rt; do
		# skip rt branch merge on 3.18 lsk, it is not already yet.
		[ $VER = '3.18' -a $x = 'rt' ] && break;

		#we only merge $TOPIC to base lsk, and then merge base lsk to others
		merger=${lsk[$x]}
		[ $x != 'base' ] && mergee=${lsk[base]}

		#only written merge message for lts to base lsk branch.
		if [ -n "$subver" -a $x == 'base' ];then
		message="Merge tag 'v$subver' into ${lsk[base]} \n\n This is the $subver stable release"
			mp="-m $(echo -e $message)"
		else
			mp="--no-edit"
		fi

		echo "### local branch preparation"
		if ! check_merger $merger; then
			echo "Failed merging on $merger: local branch error !!!" |
				mutt -s "merge failed on $mergee to $merger in $GIT_DIR" $monitor
			break;
		fi

		#Do merge
		if ! git merge $mergee "$mp"; then
			 git diff |
				mutt -s "merge failed on $mergee to $merger in $GIT_DIR" $monitor

			# clean up the dirty work tree for next kernel merge
			git merge --abort
			break;	
		fi

		#Run build testing
		if ! build_testing &> /tmp/build.log ; then
			cat /tmp/build.log |
				mutt -s "build failed on $mergee to $merger in $GIT_DIR" $monitor
			break;	
		fi

		# Set remote push branch: remote_br
		# feature only can merge to remote -test branch !!!
		[ "$TOPIC" == "lts/linux-${VER}.y" ] && remote_br=${lsk[$x]}
		[ "$TOPIC" != "lts/linux-${VER}.y" ] &&	remote_br=${lsk[$x]}-test
		PUSHB="$PUSHB ${lsk[$x]}:$remote_br"

		echo "merge and build test done on $mergee to $merger in $GIT_DIR"
	done

	# Do push
	if [ -n "$PUSHB" ]; then
		if git push origin $PUSHB &> /tmp/push.log; then
			echo "Pushed $PUSHB" | mutt -s "merged and pushed $PUSHB in $GIT_DIR" $monitor
		else
			cat /tmp/push.log | mutt -s "push failed $PUSHB in $GIT_DIR" $monitor
		fi
	fi

	
}

# ----------------------- work start ---------------------------#

#Get VER and TOPIC from input
VER=$1
TOPIC=$2
NOTESTING=$3

if [ -z "$GIT_WORK_TREE" -o -z "$GIT_DIR" -o -z "$monitor" ]; then
	echo "one of ENV value null, please check"
	echo GIT_WORK_TREE=$GIT_WORK_TREE
	echo GIT_DIR=$GIT_DIR
	echo monitor=$monitor
	exit 1
fi

#Only support current LSK version
if [ "$VER" != '3.14' -a "$VER" != '3.18' -a "$VER" != '4.1' -a "$VER" != '4.4' ]; then
	print_usage;
	exit 1
fi

do_merge_push $VER $TOPIC

