#!/bin/bash

set -ef
cd /home/build/openwrt/
cp -r /github/workspace "package/$CUSTOM_PKG_DIR"
ls "package/$CUSTOM_PKG_DIR"


make package/$PACKAGES/compile -j1 V=s

if [ -d bin/ ]; then
	ls -R bin/
	mv bin/ "$GITHUB_WORKSPACE/"
fi
