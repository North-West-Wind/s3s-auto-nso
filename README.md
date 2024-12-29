# s3s-auto-nso
Automatically grabs the `gToken` and `bulletToken` from SplatNet 3 using an Android emulator.

## Requirements
- Linux (unless you translate all the shell scripts here to other OSes)
- Android Studio
- mitmproxy
- jq

You need a working setup of Android Studio, mitmproxy and the NSO app to do this.
To do so, check [this GitHub issue](https://github.com/frozenpandaman/s3s/issues/198#issuecomment-2561475617) and my [blog post](https://blog.northwestw.in/p/2024/12/28/splatnet-3-token-mitmproxy-guide).

This can also work with [s3s-setup](https://github.com/North-West-Wind/s3s-setup).

## Usage
### Environment Variables
There are 5 environment variables for you to configure:
- `EMULATOR_DIR`: The directory where the `emulator` binary file of Android Studio can be found. (Default: `$HOME/Android/Sdk/emulator`)
- `ADB_DIR`: The directory where the `adb` binary file of Android Studio can be found. (Default: `$HOME/Android/Sdk/platform-tools`)
- `S3S_DIR`: The directory where `s3s` is set up. You most likely need to change this. (Default: `$HOME/.config/s3s`)
- `DEVICE_NAME`: The name of the AVD you want to use. You very likely need to change this. (Default: `6-33-api`)
- `PROXY_PORT`: The port for the proxy server. (Default: `8080`)

### With s3s-setup
1. Clone this repository and store it somewhere under your home directory.
2. Create a symbolic link of `run-s3s.sh` to `~/.local/bin/`. A recommended name is `s3s-nso`.
3. Run this symbolic link like you would normally do with `s3s`.

Combining all the steps, this is what commands you will run:
```bash
git clone https://github.com/North-West-Wind/s3s-auto-nso
cd s3s-auto-nso
ln -s $PWD/run-s3s.sh ~/.local/bin/s3s-nso # You can call this whatever you want
chmod +x ~/.local/bin/s3s-nso
s3s-nso -r -M 300 # Or whatever you do with normal s3s
PROXY_PORT=5678 s3s-nso -r # An example of using environment variable
```

### Without s3s-setup
Basically the same step as s3s-setup, but after cloning the repository, edit `run-s3s.sh`:
- Comment out line 9 (the `s3s -r...` line)
- Uncomment line 10 (the `(cd <dir>; python s3s.py...`)
- Change `<dir>` of line 10 to the directory where you installed s3s

### Systemd Service
This repository also comes with `s3s-nso-monitor.service`.
It can be used to run `s3s` in the background with systemd.

To use it, run the following:
```bash
cp s3s-nso-monitor.service ~/.config/systemd/user/ # Copy it to the user systemd service directory
systemctl --user daemon-reload # Reload the user systemd daemon
systemctl --user start s3s-nso-monitor # Optional: Start the monitor
systemctl --user enable s3s-nso-monitor # Optional: Autostart the monitor on boot
```

By default, it runs with the arguments `-M 300 -r`, which uploads all available previous battles and check for new battles every 5 minutes.
You may change these arguments to whatever you like.
The service also runs with `yes` to say yes to auto update so the service doesn't get stuck.

The tokens expire about every 3 hours, and the service will run the emulator in the background every time that happens.
You may experience lag if you computer is not strong enough. In that case, maybe don't use the service.

To change environment variables for the systemd service, add `Environment="<VAR>=<value>"` after the `Restart=always` line.