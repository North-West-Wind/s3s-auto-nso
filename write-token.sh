#!/usr/bin/env sh

S3S_DIR=${S3S_DIR:-"$HOME/.config/s3s"}
tmpconf=$(mktemp)
realconf="$S3S_DIR/config.txt"

tokens=$(tail -n2 gtoken_bullettoken.txt | cut -d' ' -f2)
SAVEIFS=$IFS
IFS=$'\n'
tokens=($tokens)
IFS=$SAVEIFS

gtoken="${tokens[0]}"
bullettoken="${tokens[1]}"

jq ".gtoken = \"$gtoken\" | .bullettoken = \"$bullettoken\"" "$realconf" > "$tmpconf" && mv "$tmpconf" "$realconf"