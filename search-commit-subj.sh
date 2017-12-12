#!/bin/bash

#userage: ./$0 'commit subject'
#output: list all branches which included this commit.

for x in `git log --oneline --all --grep -F "$@" | grep -F "$@" | cut -d ' ' -f 1`
do
	echo $x
	git br -a --contains $x
done
