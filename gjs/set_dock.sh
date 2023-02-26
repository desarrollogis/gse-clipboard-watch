#!/usr/bin/env bash

[ "$1" == "DEBUG" ] && set -x
XID=$(xdotool search --name "gse-clipboard-watch")
[ -z $XID ] && exit 0
INFO=$(xwininfo -id $XID | grep "X\|Y\|Width\|Height")
X=$(echo "$INFO" | grep 'Absolute upper-left X:' | awk '{print $4}')
Y=$(echo "$INFO" | grep 'Absolute upper-left Y:' | awk '{print $4}')
WIDTH=$(echo "$INFO" | grep 'Width:' | awk '{print $2}')
HEIGHT=$(echo "$INFO" | grep 'Height:' | awk '{print $2}')
WIDTH=$((WIDTH+X-1))
HEIGHT=$((HEIGHT+Y-1))
xprop -id $XID -format _NET_WM_STRUT_PARTIAL 32c -set _NET_WM_STRUT_PARTIAL "$X,$Y,$HEIGHT,0,0,0,0,0,0,$WIDTH,0,0"
exit 0
