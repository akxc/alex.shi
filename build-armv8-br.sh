#!/bin/bash

cc() {
	if git co $branch && ./armv8-OE-kernel.sh; then
		echo $branch cc OK >> $ccres
	else
		echo $branch cc failed >> $ccres
	fi
}

pushlsk() {
	if git push origin HEAD; then
		echo push $1 OK
	else
		echo push $1 FAILED !!!
	fi
}


ccres=v3.14-cc-result
for branch in $(cat v3.14-topic)
do  
	pushlsk $branch
done
