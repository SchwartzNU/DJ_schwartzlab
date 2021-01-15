#!/bin/bash

#usage: ./copySchema.sh oldDir newDir

#copy old directory to new one
cp -r +$1 +$2;

#replace strings in old directory so they refer to new directory
for f in $(find +$2);
do
  echo $f;
  sed -i'.bak' "s/$1/$2/g" $f;
done
