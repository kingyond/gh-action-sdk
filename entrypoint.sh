#!/bin/bash

set -ef
./scripts/feeds update -a

./scripts/feeds install -a

make defconfig

make package/overture/{clean,compile} -j1 V=s