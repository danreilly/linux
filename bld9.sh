#!/bin/bash
set -e
echo This script currently builds only the .dtb file for a zcu106.
echo "It is based on Analog Device's script described at"
echo "https://wiki.analog.com/resources/tools-software/linux-build/generic/zynqmp"

if [ -z `which vitis` ]; then
  echo putting Vitis into the path
  source /tools/Xilinx/Vitis/2023.2/settings64.sh
fi
if [ -z `which vivado` ]; then
  echo putting Vivado into the path
  source /tools/Xilinx/Vivado/2023.2/settings64.sh
fi



# Usage: build_zynq_kernel_image.sh [kernel_dir] [dt_file] [path_cross_toolchain]
#  If no dt_file is specified, the default is `xilinx/zynqmp-zcu102-rev10-ad9361-fmcomms2-3.dtb`
#  If no CROSS_COMPILE specified, a GCC toolchain will be downloaded
#  from Linaro's website and used.
#  Default host for Linaro's toolchain is assumed x86_64 but it can be
#  overriden with `HOST=i686 ./build_zynq_kernel_image.sh [opts]`
#
# Notes:
# - it's recommened to run this into a build dir, to make things easier to cleanup
# - this script is not particularly good at tolerating interruptions,
#   so, if you decide to interrupt this mid-way, you may need to cleanup stuff
#

#LINUX_DIR="${1:-linux}"
# DTFILE="$2"
#DTFILE="arch/arm64/boot/dts/xilinx/zynqmp-zcu106-fmcdaq3.dtb"
#DTFILE="xilinx/zynqmp-zcu106-fmcdaq3.dtb"
DTFILE="xilinx/zynqmp-zcu106-ad9988.dtb"
CROSS_COMPILE="$3"

HOST=${HOST:-x86_64}

DEFCONFIG=${DEFCONFIG:-adi_zynqmp_defconfig}
GCC_ARCH=aarch64-linux-gnu
IMG_NAME="Image"
ARCH=arm64
DTDEFAULT=xilinx/zynqmp-zcu106-ad9988.dtb

[ -n "$NUM_JOBS" ] || NUM_JOBS=5

# if CROSS_COMPILE hasn't been specified, go with a few defaults
[ -n "$CROSS_COMPILE" ] || {
	CROSS_COMPILE=${GCC_ARCH}-gcc
	if type "${GCC_ARCH}-gcc" >/dev/null 2>&1 ; then
		CROSS_COMPILE="${GCC_ARCH}-"
	else
	        echo "ERR: No cross compiler"
	        exit 1
		GCC_VERSION="8.3-2019.03"
		GCC_DIR="gcc-arm-${GCC_VERSION}-${HOST}-${GCC_ARCH}"
		GCC_TAR="$GCC_DIR.tar.xz"
		GCC_URL="https://developer.arm.com/-/media/Files/downloads/gnu-a/${GCC_VERSION}/binrel/${GCC_TAR}"
		if [ ! -d "$GCC_DIR" ] && [ ! -e "$GCC_TAR" ] ; then
			wget "$GCC_URL"
		fi
		if [ ! -d "$GCC_DIR" ] ; then
			tar -xvf $GCC_TAR || {
				echo "'$GCC_TAR' seems invalid ; remove it and re-download it"
				exit 1
			}
		fi
		CROSS_COMPILE=$(pwd)/$GCC_DIR/bin/${GCC_ARCH}-
	fi
}

# FIXME: remove the line below once Talise & Mykonos APIs
#        dont't use 1024 bytes on stack
KCFLAGS="$KCFLAGS -Wno-error=frame-larger-than="
export KCFLAGS

# FIXME: remove this function once kernel gets upgrade and
#        GCC doesn't report these warnings anymore
GCC="${CROSS_COMPILE}gcc"
if [ "$($GCC -dumpversion | cut -d. -f1)" -ge "8" ]; then
	KCFLAGS="$KCFLAGS -Wno-error=stringop-truncation"
	KCFLAGS="$KCFLAGS -Wno-error=packed-not-aligned"
	KCFLAGS="$KCFLAGS -Wno-error=stringop-overflow= -Wno-error=sizeof-pointer-memaccess"
	KCFLAGS="$KCFLAGS -Wno-error=missing-attributes"
fi

if [ "$($GCC -dumpversion | cut -d. -f1)" -ge "9" ]; then
	KCFLAGS="$KCFLAGS -Wno-error=address-of-packed-member -Wno-error=stringop-truncation"
fi
export KCFLAGS

# Get ADI Linux if not downloaded
# We won't do any `git pull` to update the tree, users can choose to do that manually
#[ -d "$LINUX_DIR" ] || \
#	git clone https://github.com/analogdevicesinc/linux.git "$LINUX_DIR"

export ARCH
export CROSS_COMPILE


make $DEFCONFIG

make -j$NUM_JOBS $IMG_NAME UIMAGE_LOADADDR=0x8000

make $DTFILE



echo "created: arch/arm64/$DTFILE"
echo "copy this to your boot partition as /boot/system.dtb"
