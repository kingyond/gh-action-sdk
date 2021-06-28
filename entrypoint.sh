#!/bin/bash

set -ef

cd /home/build/openwrt/


if [ -n "$KEY_BUILD" ]; then
	echo "$KEY_BUILD" > key-build
fi

cat feeds.conf.default >> feeds.conf

#shellcheck disable=SC2153
for EXTRA_FEED in $EXTRA_FEEDS; do
	echo "$EXTRA_FEED" | tr '|' ' ' >> feeds.conf
done
cat feeds.conf

./scripts/feeds update -a > /dev/null
make defconfig > /dev/null

if [ -z "$FEEDS_NEED_INSTALL" ]; then
	./scripts/feeds install -a > /dev/null
else
	for FEED in $FEEDS_NEED_INSTALL; do
		./scripts/feeds install -a -p $FEED > /dev/null
	done
fi


cp -r /github/workspace "package/$CUSTOM_PKG_DIR"
ls "package/$CUSTOM_PKG_DIR"

for pkg in $PACKAGES; do
	make package/$pkg/compile -j1 V=s
done


if [ -d bin/ ]; then
	ls -R bin/
	mv bin/ "$GITHUB_WORKSPACE/"
fi
