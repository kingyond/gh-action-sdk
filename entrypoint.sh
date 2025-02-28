#!/bin/bash

set -ef

FEEDNAME="${FEEDNAME:-action}"
BUILD_LOG="${BUILD_LOG:-1}"

cd /home/build/immortalwrt/

if [ -n "$KEY_BUILD" ]; then
	echo "$KEY_BUILD" > key-build
	SIGNED_PACKAGES="y"
fi

if [ -z "$NO_DEFAULT_FEEDS" ]; then
	cat feeds.conf.default >> feeds.conf
fi

echo "src-link $FEEDNAME /feed/" >> feeds.conf

ALL_CUSTOM_FEEDS=
#shellcheck disable=SC2153
for EXTRA_FEED in $EXTRA_FEEDS; do
	echo "$EXTRA_FEED" | tr '|' ' ' >> feeds.conf
	ALL_CUSTOM_FEEDS+="$(echo "$EXTRA_FEED" | cut -d'|' -f2) "
done
ALL_CUSTOM_FEEDS+="$FEEDNAME"

cat feeds.conf

./scripts/feeds update -a > /dev/null
make defconfig > /dev/null

if [ ! -z "$CUSTOM_PKG_DIR" ];then
	cp -r "/github/workspace/$CUSTOM_SRC_DIR" "package/$CUSTOM_PKG_DIR"
fi

if [ -z "$PACKAGES" ]; then
	# compile all packages in feed
	for FEED in $ALL_CUSTOM_FEEDS; do
		./scripts/feeds install -p "$FEED" -f -a
	done
	make \
		BUILD_LOG="$BUILD_LOG" \
		SIGNED_PACKAGES="$SIGNED_PACKAGES" \
		IGNORE_ERRORS="$IGNORE_ERRORS" \
		V="$V" \
		-j "$(nproc)"
else
	# compile specific packages with checks
	for PKG in $PACKAGES; do
		for FEED in $ALL_CUSTOM_FEEDS; do
			./scripts/feeds install -p "$FEED" -f "$PKG"
		done
		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			"package/$PKG/download" V=s || \
				exit $?

		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			"package/$PKG/check" V=s 2>&1 | \
				tee logtmp

		RET=${PIPESTATUS[0]}

		if [ "$RET" -ne 0 ]; then
			echo_red   "=> Package check failed: $RET)"
			exit "$RET"
		fi

		badhash_msg="HASH does not match "
		badhash_msg+="|HASH uses deprecated hash,"
		badhash_msg+="|HASH is missing,"
		if grep -qE "$badhash_msg" logtmp; then
			echo "Package HASH check failed"
			exit 1
		fi

	done

	make \
		-f .config \
		-f tmp/.packagedeps \
		-f <(echo "\$(info \$(sort \$(package-y) \$(package-m)))"; echo -en "a:\n\t@:") \
			| tr ' ' '\n' > enabled-package-subdirs.txt

	for PKG in $PACKAGES; do
		if ! grep -m1 -qE "(^|/)$PKG$" enabled-package-subdirs.txt; then
			echo "::warning file=$PKG::Skipping $PKG due to unsupported architecture"
			continue
		fi

		make \
			BUILD_LOG="$BUILD_LOG" \
			IGNORE_ERRORS="$IGNORE_ERRORS" \
			V="$V" \
			-j "$(nproc)" \
			"package/$PKG/compile" || {
				RET=$?
				make "package/$PKG/compile" V=s -j 1
				exit $RET
			}
	done
fi

if [ -d bin/ ]; then
	mv bin/ "$GITHUB_WORKSPACE/"
fi

if [ -d logs/ ]; then
	mv logs/ "$GITHUB_WORKSPACE/"
fi