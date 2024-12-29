#!/usr/bin/env sh

# constants
emulog=/var/tmp/nso-mitm-log
mitmout='gtoken_bullettoken.txt'

# clean up previous run
rm -f $mitmout

# start mitmproxy
mitmdump -q -s s3-token-extractor.py '~u GetWebServiceToken | ~u bullet_tokens' &
mitmpid=$!
echo "Started mitmdump"

# start emulator
$HOME/Android/Sdk/emulator/emulator -avd 6-33-api -writable-system -feature -Vulkan -http-proxy 127.0.0.1:8080 > $emulog &
emupid=$!
echo "Started emulator"

# wait for emulator to start
tail -f -n0 $emulog | grep -qe "Successfully loaded snapshot 'default_boot'"
echo "Emulator loaded snapshot"
sleep 2

# launch NSO
adb shell monkey -p com.nintendo.znca 1
echo "Launched NSO app"

# keep trying to tap if no gtoken is found
while ! tail -n2 $mitmout | grep -qe "gToken"; do
	sleep 1
	adb shell input tap 270 1200
done
echo "Tapped into SplatNet 3"

# wait for response to be read
tail -f -n0 $mitmout | grep -qe "bulletToken"
echo "Token obtained"

# emulator clean up
adb shell input keyevent KEYCODE_APP_SWITCH
sleep 1
adb shell input swipe 522 1647 522 90
echo "App closed"
sleep 2

# stop emulator and mitmproxy
kill $emupid
kill $mitmpid
echo "Processes killed"