#!/bin/sh

$1
retVal=$?
echo $retVal
if [ $retVal -ne $2 ]; then
    echo "Error"
    exit 1
fi
exit 0