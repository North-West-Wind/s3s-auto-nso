#!/usr/bin/env sh

s3slog=$(mktemp)
running=1

while [ $running = 1 ]; do
	s3s -r | tee "$s3slog"

	if tail -n8 $s3slog | grep -qe "The stored tokens have expired."; then
		./get-token.sh
		./write-token.sh
		echo "Replaced tokens. Restarting s3s..."
	else
		running=0
	fi
done