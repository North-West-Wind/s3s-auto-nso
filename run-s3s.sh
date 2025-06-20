#!/usr/bin/env sh

scriptdir="$(dirname "$(readlink -f "$0")")"
s3slog=$(mktemp)
running=1

while [ $running = 1 ]; do
	# If you are not using s3s-setup, comment out this line, uncomment the next line and replace <dir> with your s3s directory
	s3s "$@" | tee "$s3slog"
	#(cd <dir>; python s3s.py "$@" | tee "$s3slog")

	if tail -n9 $s3slog | grep -qe "The stored tokens have expired."; then
		(
			cd "$scriptdir"
			./get-token.sh
			./write-token.sh
		)
		echo "Replaced tokens. Restarting s3s..."
	else
		running=0
	fi
done