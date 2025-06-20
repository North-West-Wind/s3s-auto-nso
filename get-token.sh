#!/usr/bin/env sh

# constants
EMULATOR="$HOME/Android/Sdk/emulator/emulator"
ADB=adb
#ADB_DIR="${ADB_DIR-"$HOME/Android/Sdk/platform-tools"}"
DEVICE_NAME="${DEVICE_NAME:-"4-30-play"}" # For >=v3.0.1, Android 11 Google Play image is required
S3S_CONFIG="$HOME/.config/s3s/config.txt" # Path to s3s config
NSODATA=$(mktemp -d)

# constants from imc0/nso-get-data
wvfile="$NSODATA"/nso-wv-ver.txt # File where we will cache the current SplatNet web version:
nsodir="$NSODATA"/cookies # Directory where we will temporarily store the cookie database:
snhost=api.lp1.av5ja.srv.nintendo.net # Hostname of SplatNet app server:
wvdefault=6.0.0-bbd7c576 # Last known SplatNet web version:
ckfile="$NSODATA/Cookies"

# runtime variables
emulog=$(mktemp)
tokenout="gtoken_bullettoken.txt"
old_gtoken=

out=$(jq .gtoken "$S3S_CONFIG" 2>&1)
if [ "${#out}" -eq 926 ]; then
	old_gtoken="$out"
fi

# From imc0/nso-get-data
# Check presence of essential tools
ok=true
if ! command -v "$ADB" >/dev/null; then
  echo "Error: adb not installed" >&2
  ok=false
fi
if ! command -v "$EMULATOR" >/dev/null; then
  echo "Error: emulator (executable binary) not not found" >&2
  ok=false
fi
for cmd in sqlite3 curl perl; do
  if ! command -v "$cmd" > /dev/null; then
    echo "Error: $cmd is not in your path.  Install it from your distro." >&2
    ok=false
  fi
done
mkdir -p $NSODATA

# start emulator
$EMULATOR -avd "$DEVICE_NAME" -no-audio -no-window -feature -Vulkan > $emulog &
emupid=$!
echo "Started emulator"

# wait for emulator to start
tail -f -n0 $emulog | grep -qe "Successfully loaded snapshot 'default_boot'"
echo "Loaded snapshot"
sleep 2

# launch NSO
$ADB shell monkey -p com.nintendo.znca 1 > /dev/null
echo "Launched NSO app"

# keep trying to tap if no gtoken is found
gtoken=""
tries=0
while [ -z "$gtoken" ]; do
	sleep 1
	$ADB shell input tap 270 1200
	((tries=tries+1))
	# timeout at 60 seconds
	if [ $tries -gt 60 ]; then
		echo "Timed out trying to get gToken. Closing app and retrying..."
		# close app
		$ADB shell am force-stop com.nintendo.znca
		echo "Closed app"
		sleep 2
		# re-launch app
		$ADB shell monkey -p com.nintendo.znca 1 >/dev/null
		echo "Launched NSO app"
		# reset counter
		tries=0
	fi
	# Read from Cookies
	$ADB shell su -c "cp /data/user/0/com.nintendo.znca/app_webview/Default/Cookies /storage/emulated/0/Download/"
	$ADB pull -a /storage/emulated/0/Download/Cookies "$NSODATA/" >/dev/null
	if [ -f "$ckfile" ]; then
		cdate="$(stat -c %Y "$ckfile")"
		ndate="$(date +%s)"
		if [ "$((cdate+6*3600))" -ge $ndate ]; then
			gtoken="$(sqlite3 "$NSODATA"/Cookies "select value from cookies where name='_gtoken' order by creation_utc desc limit 1;")"
		fi
		rm "$ckfile"
	fi
done
echo "Obtained new gtoken"

# From imc0/nso-get-data
# Attempt to get the SplatNet web version
nsover=""
# try to figure out the main JS filename from SplatNet index
js="$(curl -s "https://$snhost/" | grep -a -o 'main\.[0-9a-f]*\.js')"
if [ -n "$js" ]; then
  # try to parse the JS file to extract the web view version
  nsover="$(curl -s "https://$snhost/static/js/$js" | perl -lne 'print "$2$1" if /null===\(..="([0-9a-f]{8}).{60,120}`,..=`([0-9.]+-)/;')"
fi
if [ -n "$nsover" ]; then echo "$nsover" > "$wvfile"
else echo "Warning: failed to get SplatNet web version from NSO." >&2
fi
[ -z "$nsover" ] && nsover=$wvdefault

# Attempt to get a bulletToken from our gtoken
out="$(curl -s -X POST -H 'Content-Type: application/json' -H "X-Web-View-Ver: $nsover" -H 'accept-language: en-US' -H 'x-nacountry: US' -b "_gtoken=$gtoken" "https://$snhost/api/bullet_tokens")"
case "$out" in
  *bulletToken*)
    bt="$(echo "$out" | tr -d \" | tr '{},' '\012' | grep bulletToken | cut -d: -f2)"
    if [ -z "$bt" ]; then echo "Error: failed to parse the bulletToken from web response" >&2
    elif [ "${#bt}" -ne 124 ]; then
      echo "Error: returned bulletToken is the wrong length" >&2
    fi
    ;;
  *) echo "Error: Nintendo did not give us a bulletToken." >&2
   	if [ -n "$out" ]; then
     	echo ""
     	echo "Error data: $out"
   	fi
esac

# Write tokens to output
echo "gtoken $gtoken" > "$tokenout"
echo "bullettoken $bt" >> "$tokenout"
echo "Wrote tokens to $tokenout"

# emulator clean up
$ADB shell am force-stop com.nintendo.znca
echo "Closed app"
sleep 2

# stop emulator
kill $emupid
echo "Killed processes"