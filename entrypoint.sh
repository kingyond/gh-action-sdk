#!/bin/bash

set -ef

cat feeds.conf.default >> feeds.conf

#shellcheck disable=SC2153
for EXTRA_FEED in $EXTRA_FEEDS; do
	echo "$EXTRA_FEED" | tr '|' ' ' >> feeds.conf
done
cat feeds.conf

cd /home/build/openwrt/
cp -r /github/workspace "package/$CUSTOM_PKG_DIR"
ls "package/$CUSTOM_PKG_DIR"


make package/$PACKAGES/compile -j1 V=s

if [ -d bin/ ]; then
	ls -R bin/
	mv bin/ "$GITHUB_WORKSPACE/"
fi
