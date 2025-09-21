#!/bin/bash
export WAYLAND_DISPLAY=mysocket
weston --socket=$WAYLAND_DISPLAY --backend=x11-backend.so --width=1920 --height=1080 &
cmd1_pid=$!
waydroid show-full-ui &
wait $cmd1_pid
waydroid session stop
echo 'waydroid session stopped successfully!'