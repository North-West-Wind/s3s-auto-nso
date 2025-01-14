#!/usr/bin/env sh

EMULATOR_DIR="${EMULATOR_DIR:-"$HOME/Android/Sdk/emulator"}"
DEVICE_NAME="${DEVICE_NAME:-"6-33-api"}"

$EMULATOR_DIR/emulator -avd "$DEVICE_NAME" -writable-system -feature -Vulkan