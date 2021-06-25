#!/bin/bash

set -ef
cd /home/build/openwrt/
./scripts/feeds update -a

./scripts/feeds install -a

make defconfig

make package/overture/{clean,compile} -j1 V=s