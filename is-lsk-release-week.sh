#!/bin/bash

today=`date +%d`
lastTh=`cal | awk '{print $5}' | grep -E '[0-9]' | tail -n 1`

# today is in LSK release week.
if [ $today -gt `expr $lastTh - 4` -a $today -lt `expr $lastTh + 1` ]; then
	exit 0
else
	exit 1
fi
