#!/bin/bash
# parameter $1, the backport base kernel; $2, upstream branch name or tag.
# Using on backported branch
#
# This script will check all cherry picked(-sx) commits id, to see if it was 
# mentioned/fixed in later commit log -- between base kernel and latest upstream.

IFS=$'\n'
pickedcommit=`git log --reverse ${1}.. | grep 'cherry picked from commit' | awk  '{print $5}'`

for i in $pickedcommit; do
	# any commit mentioned the picked commit $i?
	fix=`git log --oneline --grep=${i:0:7} ${1}..${2}`

	for f in $fix; do
		# was it picked already? or we may need this commit.
		gotfix=`git log --oneline --grep=${f:0:7} ${1}..`
		[ -z "$gotfix" ] && echo $f
	done
done
