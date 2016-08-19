#!/bin/bash
# Copyright Alex Shi <alex.shi@linaro.org>
#
# This script will insert the related To:/Cc: list for patches
# used under the kernel source directory for scripts/get_maintainer.pl

# usage: ./$0 prepared_patch.patch "A <a@a.com>; b@b.org"
# the second parameter is extra Cc list email address with space as seperator

tmpfile=/tmp/`date +%s`
tofile=${tmpfile}_to
ccfile=${tmpfile}_cc

# someone don't use the old email address now.
blacklist="glommer@redhat.com alex.shi@intel.com"

scripts/get_maintainer.pl $1 > $tmpfile

cp $tmpfile $tofile
cp $tmpfile $ccfile

if [ -n "$2" ]; then
	extra_cc="$2"
	while IFS=';' read -ra ADDR; do
		for i in "${ADDR[@]}"; do
			echo "$i" >> $ccfile
		done
	done <<< "$extra_cc"
fi

# left maintainers in tofile and commiters in ccfile
sed -i -e "/maintainer/d" -e 's/(.*)//g' $ccfile 
sed -i -e "/commit_signer/d" -e 's/(.*)//g' $tofile

for i in `echo $blacklist`; do
	sed -i "/$i/d" $ccfile
	sed -i "/$i/d" $tofile
done

# skip duplicate persons.
while read x; do
	sed -i "/$x/d" $ccfile
done < $tofile

# insert cc list
while read x;do
	grep "^Cc: $x" $1 && continue
	echo "Cc: $x"
	sed "/Signed-off-by:.*/a Cc: $x" -i $1
done < $ccfile

# insert to list
while read x;do
	grep "^To: $x" $1 && continue
	echo "To: $x"
	sed "/Signed-off-by:.*/a To: $x" -i $1
done < $tofile

rm $tmpfile*
