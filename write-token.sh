#!/usr/bin/env sh

tmpconf=$(mktemp)
realconf="$HOME/.config/s3s/config.txt"

tokens=$(tail -n2 gtoken_bullettoken.txt | cut -d' ' -f2)
SAVEIFS=$IFS
IFS=$'\n'
tokens=($tokens)
IFS=$SAVEIFS

gtoken="${tokens[0]}"
bullettoken="${tokens[1]}"

jq ".gtoken = \"$gtoken\" | .bullettoken = \"$bullettoken\"" "$realconf" > "$tmpconf" && mv "$tmpconf" "$realconf"