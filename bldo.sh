
DTFILE="xilinx/overlay.dtbo"
CROSS_COMPILE="$3"
HOST=${HOST:-x86_64}
DEFCONFIG=${DEFCONFIG:-adi_zynqmp_defconfig}
GCC_ARCH=aarch64-linux-gnu
IMG_NAME="Image"
ARCH=arm64
DTDEFAULT=xilinx/zynqmp-zcu106-fmcdaq3.dtb

KCFLAGS="$KCFLAGS -Wno-error=frame-larger-than="
export KCFLAGS
export ARCH
export CROSS_COMPILE


# make DTC_FLAGS=-@ xilinx/zynqmp-zcu106-fmcdaq3.dtb
make $DTFILE
echo "created: arch/arm64/boot/dts/$DTFILE"
make "xilinx/chclk.dtbo"
