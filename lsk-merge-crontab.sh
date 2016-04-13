#!/bin/bash

export GIT_WORK_TREE=/home/alexs/lsk/kernel
export GIT_DIR=$GIT_WORK_TREE/.git/
export monitor="alex.shi@linaro.org mark.brown@linaro.org"

merge_log=~/lsk/lsk-auto-pick.log

git --git-dir=/home/alexs/lsk/kernel/.git remote update &&
echo "`date`" >> $merge_log
for i in 3.18 4.1 4.4; do
	/home/alexs/lsk/scripts/merge-topic.sh $i &>> $merge_log
done
