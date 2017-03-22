#!/bin/bash
# parameter $1, the backport base kernel; $2, upstream branch name or tag.
# Using on backported branch
#
# This script will check all cherry picked(-sx) commits id, to see if it was 
# mentioned/fixed in later commit log -- between base kernel and latest upstream.

export GIT_WORK_TREE=/home/alexs/lsk/kernel
export GIT_DIR=$GIT_WORK_TREE/.git/
UPSTREAMBR=linux
monitors="alex.shi@linaro.org"

function searchcid4topic() {
	IFS=$'\n'
	targetcids="/tmp/$TOPIC"
	mkdir -p "$(dirname "$targetcids")" && touch "$targetcids"
	> $targetcids

	PICKEDCID=`git log --reverse ${LTSBR}..${TOPIC} | \
		grep 'cherry picked from commit' | awk  '{print $5}'`

	local patterns;
	for i in $PICKEDCID; do
		patterns="$patterns --grep=\"\<${i:0:7}\""
	done

	#[ -z "$patterns" ] && return

	# get all commits which mentioned a picked commit $patterns
	echo -e "\n----------all fixing commits-----------\n" > $targetcids
	cmd="git log --oneline --reverse ${patterns} ${LTSBR}..${UPSTREAMBR} &>> $targetcids"
	if ! eval $cmd; then
		echo -e "check $TOPIC failed on command \n $cmd\n" >>$targetcids
		return
	fi
	echo -e "\n----------what we missed-----------\n" >> $targetcids

	for f in `cat $targetcids`; do
		# only check the fix cid which isn't in our $topic.
		[ "${f:0:7}" = "-------" ] && continue;
		fixed=$(git log --oneline --grep="\<${f:0:7}" ${LTSBR}..${TOPIC})
		[ -z "$fixed" ] && echo $f >> $targetcids
	done

	cat $targetcids | mutt -s "$TOPIC: fix condidates" $monitors
}

for version in 4.1 4.4 4.9;
do

LTSBR="lts/linux-${version}.y"
	topics=`git branch -r | grep "v$version/topic/"`
	for TOPIC in $topics; do
		searchcid4topic
	done
done
