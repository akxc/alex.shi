#!/bin/bash

export GIT_WORK_TREE=/home/alexs/lsk/kernel
export GIT_DIR=$GIT_WORK_TREE/.git/
export monitor="alex.shi@linaro.org mark.brown@linaro.org"

git --git-dir=/home/alexs/lsk/kernel/.git remote update &&
for i in 3.14 3.18 4.1 4.4; do
	bash -x /home/alexs/lsk/scripts/merge-topic.sh $i &>> ~/lsk/lsk-auto-pick.log
done
