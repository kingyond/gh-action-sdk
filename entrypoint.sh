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
		./scripts/feeds install -d y -a
	else
		for FEED in $FEEDS_NEED_INSTALL; do
			./scripts/feeds install -d y -a -p $FEED -f > /dev/null
		done
	fi

	if [ ! -z "$SCRIPT_BEFORE_BUILD" ]; then
		echo "Run script before build..."
		echo "$SCRIPT_BEFORE_BUILD"
		sh -c "$SCRIPT_BEFORE_BUILD"
	fi

	make \
		-j "$(nproc)" \
		V="$V"

else
	if [ -z "$FEEDS_NEED_INSTALL" ]; then
		./scripts/feeds install -a
	else
		for FEED in $FEEDS_NEED_INSTALL; do
			./scripts/feeds install -a -p $FEED -f > /dev/null
		done
	fi

	if [ ! -z "$SCRIPT_BEFORE_BUILD" ]; then
		echo "Run script before build..."
		echo "$SCRIPT_BEFORE_BUILD"

		bash -c "$SCRIPT_BEFORE_BUILD"
	fi

	for pkg in $PACKAGES; do
		blacked_archs=$(echo "$pkg" | awk -F'|' '{printf $2}')
		p=$(echo "$pkg" | awk -F'|' '{printf $1}')
		if [ ! -z $blacked_archs ];then
			blacked=''
			IFS=',' read -r -a array <<< "$blacked_archs"
			for arch in "${array[@]}"
			do
				if [ $ARCH = $arch ]; then
					blacked=$arch
				fi
			done

			if [ -z $blacked ]; then
				echo "Package support current architecture, continue..."
				echo "Start building $p..."
				make package/$p/compile \
					-j "$(nproc)" \
					V="$V"
			else
				echo "$p 不支持 $blacked 跳过"
			fi
		else
			echo "Package support all architecture, continue..."
			echo "Start building $pkg..."
			make package/$pkg/compile \
				-j "$(nproc)" \
				V="$V"
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
