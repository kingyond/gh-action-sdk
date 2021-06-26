#!/bin/bash

set -ef
cd /home/build/openwrt/
cp -r /github/workspace "package/$CUSTOM_PKG_DIR"
ls "package/$CUSTOM_PKG_DIR"

ls -R