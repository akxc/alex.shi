#!/bin/bash
#
# This script will check all cherry picked(-sx) commits id, to see if it was 
# mentioned/fixed in later commit log -- between base LTS and latest upstream.

export GIT_WORK_TREE=/home/alexs/lsk/kernel
export GIT_DIR=$GIT_WORK_TREE/.git/
UPSTREAMBR=linux
monitors="alex.shi@linaro.org"

#search fixed cid for a given topic branch
function searchcid4topic() {
	local topic="$1"
	IFS=$'\n'
	targetcids="/tmp/$topic"
	mkdir -p "$(dirname $targetcids)" && touch "$targetcids"
	> $targetcids

	#get all cherry-picked commits for this topic
	pickedid=`git log --reverse ${LTSBR}..${topic} |
		grep 'cherry picked from commit' | awk  '{print $5}'`

	#some branch using "commit xxxxx upstream" to mark pickup
	if [ "$pickedid" = "" ]; then
		pickedid=`git log --reverse ${LTSBR}..${topic} |
			grep -e "^    commit [a-z0-9]\{40\} upstream.$" | awk '{print $2}'`
	fi

	#no formated pickup found
	if [ -z "$pickedid" ];then
		echo "no formatted picked cid found" | mutt -s "no formatted picking in $topic" $monitors
		return
	fi

	local patterns;
	for i in $pickedid; do
		patterns="$patterns --grep=\"\<${i:0:7}\""
	done

	#search all commits which mentioned any picked commits in $patterns
	echo -e "\n----------all fixing commits-----------\n" > $targetcids
	cmd="git log --oneline --reverse ${patterns} ${LTSBR}..${UPSTREAMBR} &>> $targetcids"
	if ! eval $cmd; then
		echo -e "check $topic failed on command \n $cmd\n" |
				mutt -s "Failed on $topic checking" $monitors
		return
	fi
	echo -e "\n----------what we missed-----------\n" >> $targetcids

	#Just report omitted fixing commits, not the one we picked.
	for f in `cat $targetcids`; do
		# only check the fix cid which isn't in our $topic.
		[ "${f:0:7}" = "-------" ] && continue;
		fixed=$(git log --oneline --grep="\<${f:0:7}" ${LTSBR}..${topic})
		[ -z "$fixed" ] && echo $f >> $targetcids
	done

	cat $targetcids | mutt -s "$topic: fix condidates" $monitors
}

#check lsk version 4.1/4.4/4.9 now
for version in 4.1 4.4 4.9; do
LTSBR="lts/linux-${version}.y"
	topics=`git branch -r | grep "v$version/topic/"`
	for t in $topics; do
		searchcid4topic $t
		unset IFS;
	done
done
