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

function searchcid() {
	IFS=$'\n'
	targetcids="/tmp/$TOPIC"
	mkdir -p "$(dirname "$targetcids")" && touch "$targetcids"
	> $targetcids
	for i in $PICKEDCID; do
		# any commit mentioned a picked commit $i?
		fixes=`git log --oneline --reverse --grep=${i:0:7} ${LTSBR}..${UPSTREAMBR}`

		for f in $fixes; do
			# only check the fix cid which isn't in our $topic.
			gotfix=`git log --oneline --grep=${f:0:7} ${LTSBR}..${TOPIC}`
			[ -z "$gotfix" ] && echo $f >> $targetcids
		done
	done
	cat $targetcids | mutt -s "find fix condidates for $TOPIC " $monitors
}

#for version in 4.1 4.4 4.9;
for version in 4.4
do
	LTSBR="lts/linux-${version}.y"
	topics=`git branch -r | grep "v$version/topic/"`
	for TOPIC in $topics; do
		PICKEDCID=`git log --reverse ${LTSBR}..${TOPIC} | \
			grep 'cherry picked from commit' | awk  '{print $5}'`
		searchcid
	done
done
