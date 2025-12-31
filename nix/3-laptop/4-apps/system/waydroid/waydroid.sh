#!/usr/bin/env bash

# Create the launch script for weston
LAUNCH_SCRIPT=$(mktemp)
tee $LAUNCH_SCRIPT <<EOF
sleep 3 &&
waydroid session start &
sleep 3 &&
waydroid show-full-ui &
wait
EOF
chmod +x $LAUNCH_SCRIPT

# Start the waydroid container
sudo systemctl start waydroid-container &

# Wait for the container to initialize
sleep 3;

# Launch Weston and wait for it to exit
weston --socket=wayland-0 --backend=x11-backend.so --width=1920 --height=1080 -- $LAUNCH_SCRIPT
process_id=$!
wait $process_id

# Do cleanups
pkill weston
waydroid session stop
sudo pkill waydroid
sudo systemctl stop waydroid-container
echo 'waydroid session stopped successfully!'