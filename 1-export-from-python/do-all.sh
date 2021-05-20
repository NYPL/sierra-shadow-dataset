#!/bin/bash

set -e
set -x

GEN_LOCATION="/home/tony/data/nypl-sql-dumps/"
EXPDATE=$(ls "$GEN_LOCATION" | sort | tail -n 1)
EXACT_LOCATION="$GEN_LOCATION$EXPDATE"

BIB_PATH=$(ls $EXACT_LOCATION | grep bib)
BIB_PATH=$EXACT_LOCATION/$BIB_PATH
ITEM_PATH=$(ls $EXACT_LOCATION | grep item)
ITEM_PATH=$EXACT_LOCATION/$ITEM_PATH

echo $BIB_PATH
echo $ITEM_PATH

# BIBS
zcat $BIB_PATH | ./bibs/export-bib-info-first-step.py
pigz exported-bibs-raw-from-python.dat
mv exported-bibs-raw-from-python.dat.gz ./bibs/exported-bibs-raw-from-python-$EXPDATE.dat.gz

# ITEMS
zcat $ITEM_PATH | ./items/export-item-info-first-step.py
rm item-error-log.txt # !!
pigz exported-items-raw-from-python.dat
mv exported-items-raw-from-python.dat.gz ./items/exported-items-raw-from-python-$EXPDATE.dat.gz


