#!/bin/bash
# Copyright Alex Shi <alex.shi@linaro.org>
#
# usage: ./$0 prepared_patch.patch

tmpfile=/tmp/`date +%s`
tofile=${tmpfile}_to
ccfile=${tmpfile}_cc
blacklist="glommer@redhat.com"

scripts/get_maintainer.pl $@ > $tmpfile

cp $tmpfile $tofile
cp $tmpfile $ccfile

sed -i -e "/maintainer/d" -e 's/(.*)//g' $ccfile 
sed -i -e "/commit_signer/d" -e 's/(.*)//g' $tofile

for i in `echo $blacklist`; do
	sed -i "/$i/d" $ccfile
	sed -i "/$i/d" $tofile
done

while read x; do
	sed -i "/$x/d" $ccfile
done < $tofile

while read x;do
	grep "^Cc: $x" $1 && continue
	echo "Cc: $x"
	sed "/Signed-off-by:.*/a Cc: $x" -i $1
done < $ccfile

while read x;do
	grep "^To: $x" $1 && continue
	echo "To: $x"
	sed "/Signed-off-by:.*/a To: $x" -i $1
done < $tofile

rm $tmpfile*
