#!/usr/bin/env sh

# constants
EMULATOR_DIR="${EMULATOR_DIR:-"$HOME/Android/Sdk/emulator"}"
ADB_DIR="${ADB_DIR-"$HOME/Android/Sdk/platform-tools"}"
DEVICE_NAME="${DEVICE_NAME:-"6-33-api"}"
PROXY_PORT="${PROXY_PORT:-"8080"}"
emulog=$(mktemp)
mitmout='gtoken_bullettoken.txt'

# clean up previous run
rm -f $mitmout

# start mitmproxy
mitmdump -q -p "$PROXY_PORT" -s s3-token-extractor.py '~u GetWebServiceToken | ~u bullet_tokens' &
mitmpid=$!
echo "Started mitmdump"

# start emulator
$EMULATOR_DIR/emulator -avd "$DEVICE_NAME" -writable-system -no-window -no-audio -feature -Vulkan -http-proxy "127.0.0.1:$PROXY_PORT" > $emulog &
emupid=$!
echo "Started emulator"

# wait for emulator to start
tail -f -n0 $emulog | grep -qe "Successfully loaded snapshot 'default_boot'"
echo "Loaded snapshot"
sleep 2

# launch NSO
$ADB_DIR/adb shell monkey -p com.nintendo.znca 1 > /dev/null
echo "Launched NSO app"

# keep trying to tap if no gtoken is found
tries=0
while ! tail -n2 $mitmout | grep -qe "gToken"; do
	sleep 1
	$ADB_DIR/adb shell input tap 270 1200
	((tries=tries+1))
	# timeout at 60 seconds
	if [ $tries -gt 60 ]; then
		echo "Timed out trying to get gToken. Closing app and retrying..."
		# close app
		$ADB_DIR/adb shell am force-stop com.nintendo.znca
		echo "Closed app"
		sleep 2
		# re-launch app
		$ADB_DIR/adb shell monkey -p com.nintendo.znca 1 > /dev/null
		echo "Launched NSO app"
		# reset counter
		tries=0
	fi
done
echo "Tapped into SplatNet 3"

# wait for response to be read
tail -f -n0 $mitmout | grep -qe "bulletToken"
echo "Obtained tokens"

# emulator clean up
$ADB_DIR/adb shell am force-stop com.nintendo.znca
echo "Closed app"
sleep 2

# stop emulator and mitmproxy
kill $emupid
kill $mitmpid
echo "Killed processes"