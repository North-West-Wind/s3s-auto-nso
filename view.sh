#!/usr/bin/env sh

EMULATOR_DIR="${EMULATOR_DIR:-"$HOME/Android/Sdk/emulator"}"
DEVICE_NAME="${DEVICE_NAME:-"4-30-play"}"

#mitmweb &
#mitmpid=$!

#$EMULATOR_DIR/emulator -avd "$DEVICE_NAME" -feature -Vulkan -http-proxy "127.0.0.1:8080"
$EMULATOR_DIR/emulator -avd "$DEVICE_NAME" -feature -Vulkan

#wait $mitmpid
