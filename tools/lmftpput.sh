#!/bin/sh

# Transfers all files below $1 to a Lisp Machine via FTP.

HOST=10.0.0.2
LM=LAMA

DIRS=$(find $1 -type d)
FILES=$(find $1 -type f)

echo 'set timeout -1'
echo "spawn ftp $HOST"
echo 'expect "ftp> "'

for x in $DIRS; do
    base=${x#$1/}
    lmdir=$(echo $base\; | sed 's@/@.@g')
    lmd=$(echo $LM:$lmdir | tr '[a-z]' '[A-Z]')

    if [ $x = $1 ]; then
	continue;
    fi
    echo send \"mkdir $lmd\\r\"
    echo 'expect "ftp> "'
done

for x in $FILES; do
    base=${x#$1/}
    dir=$(dirname $base)
    fname=$(basename $base)

    lmdir=$(echo $dir\; | sed 's@/@.@g')
    lmfile=$(echo $fname | sed 's@^\(.*\)\.\(.*\)\.\(.*\)$@\1.\2#\3@g')
    lmfn=$(echo $LM:$lmdir$lmfile | tr '[a-z]' '[A-Z]')

    echo send \"put $x $lmfn\\r\"
    echo 'expect "ftp> "'
done

echo 'send "bye\r"'
