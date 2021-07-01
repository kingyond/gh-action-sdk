#!/bin/bash

set -ef

cd /home/build/openwrt/

for pkg in $PACKAGES; do
	blacked_archs=$(echo "$pkg" | awk '{printf $2}')
	p=$(echo "$pkg" | awk '{printf $1}')
	echo "==="
	echo "$blacked_archs"
	echo "$p"
	if [ ! -z $blacked_archs ];then
		blacked=''
		blacked_archs_arr='|' read -r -a array <<< "$blacked_archs"
		for arch in "${array[@]}"
		do
			echo "$arch"
			if [ $ARCH = $arch ]; then
				blacked=$arch
			fi
		done

		if [ -z $blacked ]; then
			echo "支持当前架构"
		else
			echo "$p 不支持 $blacked"
		fi
	else
		echo "支持所有架构"
	fi
done