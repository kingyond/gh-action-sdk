#!/bin/bash

set -ef

cd /home/build/openwrt/

sudo apt-get update
sudo apt-get install upx -y
cp /usr/bin/upx staging_dir/host/bin
cp /usr/bin/upx-ucl staging_dir/host/bin


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

if [ ! -z "$CUSTOM_PKG_DIR" ];then
	cp -r /github/workspace "package/$CUSTOM_PKG_DIR"
fi


if [ -z "$PACKAGES" ]; then
	# compile all packages in feed

	if [ -z "$FEEDS_NEED_INSTALL" ]; then
		./scripts/feeds install -d y -f -a
	else
		for FEED in $FEEDS_NEED_INSTALL; do
			./scripts/feeds install -d y -a -p $FEED -f > /dev/null
		done
	fi

	echo "$SCRIPT_BEFORE_BUILD"
	if [ ! -z "$SCRIPT_BEFORE_BUILD" ]; then
		echo "Run script before build..."
		sh -c "$SCRIPT_BEFORE_BUILD"
	fi

	make \
		-j "$(nproc)" \
		V=s

else
	if [ -z "$FEEDS_NEED_INSTALL" ]; then
		./scripts/feeds install -f -a
	else
		for FEED in $FEEDS_NEED_INSTALL; do
			./scripts/feeds install -a -p $FEED -f > /dev/null
		done
	fi

	echo "$SCRIPT_BEFORE_BUILD"

	if [ ! -z "$SCRIPT_BEFORE_BUILD" ]; then
		echo "Run script before build..."
		sh -c "$SCRIPT_BEFORE_BUILD"
	fi

	for pkg in $PACKAGES; do
		local support_archs=$(echo "$pkg" | awk '{printf $2}')
		local p=$(echo "$pkg" | awk '{printf $1}')
		if [ ! -z $support_archs ];then
			sup='|' read -r -a array <<< "$support_archs"
			for arch in "${array[@]}"
			do
				if [ $ARCH = $arch ]; then
					make package/$p/compile \
						-j "$(nproc)" \
						V=s
				fi
			done
		else
			make package/$pkg/compile \
				-j "$(nproc)" \
				V=s
		fi
	done
fi

if [ "$INDEX" = 1 ];then
	make package/index
fi


if [ -d bin/ ]; then
	ls -R bin/
	mv bin/ "$GITHUB_WORKSPACE/"
fi
