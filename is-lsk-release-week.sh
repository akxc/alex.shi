#!/bin/bash

today=`date +%d`
#maybe the awk record char as _\bx, anyway the commented line may make the $lastTh mess
#lastTh=`cal -N |awk '/^Th/ {print $(NF)}'`
lastTh=`cal -h|cut -c13,14|sed '/^ *$/d'|tail -1`

# today is in LSK release week.
if [ $today -gt $(expr $lastTh - 4) -a $today -lt $(expr $lastTh + 1) ]; then
	exit 0
else
	exit 1
fi
