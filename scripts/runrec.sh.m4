#!/bin/bash

echo -n "START TIME: "
date
#. ___SCRIPTPATH___/alijkl ___ALIROOT_VERSION___
cd ___WORKDIR___ || exit -1
. alisetup ___ALIROOT_VERSION___
which aliroot
printenv > environment.log
aliroot -l -q -b rec.C

tstamp=$(date)
echo -n "END TIME: $tstamp"

while read file; do
    rm $file
done < remove.lst

chunkgrep=$(grep "Creating raw-reader in order to read raw-data file" rec.batch.log | cut -c 77-)
successgrep=$(grep "rec.C completed" rec.batch.log)
crashgrep=$(grep kSigSegmentationViolation rec.batch.err)
if [ -e core ]; then
crashgrep="core dump found";
fi

if [ -z "$crashgrep" ]; then
    if [ -z "$chunkgrep" ]; then
	echo "$chunkgrep strange ($tstamp)" >> ../jobs.txt
    else
	echo "$chunkgrep completed ($tstamp)" >> ../jobs.txt
    fi
else
    echo "$chunkgrep crashed ($tstamp)" >> ../jobs.txt
fi

echo "runrec.sh finished"
