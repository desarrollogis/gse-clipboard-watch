#!/usr/bin/env bash

[ "$1" == "DEBUG" ] && set -x
XID=$(xdotool search --name "gse-clipboard-watch window")
INFO=$(xwininfo -id "$XID" | grep "X\|Y\|Width\|Height")
X=$(echo "$INFO" | grep 'Absolute upper-left X:' | awk '{print $4}')
Y=$(echo "$INFO" | grep 'Absolute upper-left Y:' | awk '{print $4}')
WIDTH=$(echo "$INFO" | grep 'Width:' | awk '{print $2}')
HEIGHT=$(echo "$INFO" | grep 'Height:' | awk '{print $2}')
WIDTH=$((X + WIDTH - 1))
HEIGHT=$((Y + HEIGHT - 1))
xprop -id "$XID" -format _NET_WM_STRUT_PARTIAL 32c -set _NET_WM_STRUT_PARTIAL "$X,$Y,$HEIGHT,0,0,0,0,0,0,$WIDTH,0,0"
exit 0
