#!/bin/bash
#Script to build buildroot configuration
#Author: Siddhant Jajoo

source shared.sh

EXTERNAL_REL_BUILDROOT=../base_external

# Buildroot 2024.02's host-m4 does not compile with GCC 15's default C23 mode.
# Keep the target build unchanged while using the last broadly supported C mode
# for host tools on newer host compilers.
if [ -n "${HOST_CFLAGS:-}" ]; then
	BUILDROOT_HOST_CFLAGS="${HOST_CFLAGS}"
elif [ "$(gcc -dumpversion | cut -d. -f1)" -ge 15 ]; then
	BUILDROOT_HOST_CFLAGS="-O2 -std=gnu17"
fi

buildroot_make() {
	if [ -n "${BUILDROOT_HOST_CFLAGS:-}" ]; then
		make -C buildroot HOST_CFLAGS="${BUILDROOT_HOST_CFLAGS}" "$@"
	else
		make -C buildroot "$@"
	fi
}

git submodule init
git submodule sync
git submodule update

set -e 
cd `dirname $0`

if [ ! -e buildroot/.config ]
then
	echo "MISSING BUILDROOT CONFIGURATION FILE"

	if [ -e ${AESD_MODIFIED_DEFCONFIG} ]
	then
		echo "USING ${AESD_MODIFIED_DEFCONFIG}"
		buildroot_make defconfig BR2_EXTERNAL=${EXTERNAL_REL_BUILDROOT} BR2_DEFCONFIG=${AESD_MODIFIED_DEFCONFIG_REL_BUILDROOT}
	else
		echo "Run ./save_config.sh to save this as the default configuration in ${AESD_MODIFIED_DEFCONFIG}"
		echo "Then add packages as needed to complete the installation, re-running ./save_config.sh as needed"
		buildroot_make defconfig BR2_EXTERNAL=${EXTERNAL_REL_BUILDROOT} BR2_DEFCONFIG=${AESD_DEFAULT_DEFCONFIG}
	fi
else
	echo "USING EXISTING BUILDROOT CONFIG"
	echo "To force update, delete .config or make changes using make menuconfig and build again."
	buildroot_make BR2_EXTERNAL=${EXTERNAL_REL_BUILDROOT}

fi
