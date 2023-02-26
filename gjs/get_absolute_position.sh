#!/usr/bin/env bash

[ "$1" == "DEBUG" ] && set -x
XID=$(xdotool search --name "Clipboard Watch")
[ -z $XID ] && exit 0
INFO=$(xwininfo -id $XID | grep "X\|Y\|Width\|Height")
X=$(echo "$INFO" | grep 'Absolute upper-left X:' | awk '{print $4}')
Y=$(echo "$INFO" | grep 'Absolute upper-left Y:' | awk '{print $4}')
WIDTH=$(echo "$INFO" | grep 'Width:' | awk '{print $2}')
HEIGHT=$(echo "$INFO" | grep 'Height:' | awk '{print $2}')
echo $X $Y $WIDTH $HEIGHT
exit 0
