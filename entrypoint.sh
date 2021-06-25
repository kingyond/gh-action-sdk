#!/bin/bash

set -ef
cd /home/build/openwrt/
cp -r /github/workspace "package/$CUSTOM_PKG_DIR"
./scripts/feeds update -a
make defconfig
./scripts/feeds install -a


make package/$PACKAGES/{clean,compile} -j1 V=s