#!/bin/bash

set -ef
cd /home/build/openwrt/
echo "dir $CUSTOM_PKG_DIR"
cp -r /github/workspace "package/$CUSTOM_PKG_DIR"
ls "package/$CUSTOM_PKG_DIR"
echo "ahhhh"

ls -R