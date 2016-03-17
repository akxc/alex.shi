#!/bin/bash
# Copyright Alex Shi <alex.shi@intel.com>

tmpfile=/tmp/`date +%s`
tofile=${tmpfile}_to
ccfile=${tmpfile}_cc
blacklist="glommer@redhat.com"

scripts/get_maintainer.pl $@ > $tmpfile

to=`cat $tmpfile | grep -e '<' | grep -e  maintainer | sed 's/.*\(<.*>\).*/\1/g' | sed -e 's/<//g' -e 's/>//g'`
cc=`cat $tmpfile | grep -e '<' | grep -e  commit_signer | sed 's/.*\(<.*>\).*/\1/g' | sed -e 's/<//g' -e 's/>//g'`

echo $to > $tofile 
echo $cc > $ccfile

for i in `cat $tofile`; do
	sed -i s/${i}//g $ccfile
done
for i in `echo $blacklist`; do
	sed -i s/$i//g $ccfile
done

echo `cat $tofile | awk '{for (i=1;i<=NF;i++) print "--to " $i}'` `cat $ccfile | awk '{for (i=1;i<=NF;i++) print "--cc " $i}'` " --cc linux-kernel@vger.kernel.org "

rm $tmpfile*
