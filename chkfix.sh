#!/bin/bash
# parameter $1, the backported base kernel; $2, upstream branch name or tag
# Used on backported branch
#
# this script will check all cherry pick commits id, to see if it was mentioned
# in later commit log -- between base kernel and latest upstream.

pickedcommit=`git log --reverse ${1}.. | grep 'cherry picked from commit' | awk  '{print $5}'`
for i in $pickedcommit; do
	git log --oneline --grep=${i:0:7} ${1}..${2}
done
