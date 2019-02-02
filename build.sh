#!/bin/bash
rm .version
# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image"
DTBIMAGE="dtb"
export CLANG_PATH=~/bin/linux-x86/clang-4691093/bin/
export PATH=${CLANG_PATH}:${PATH}
export LD_LIBRARY_PATH=:${LD_LIBRARY_PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=~/bin/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export DTC_EXT=/home/androplus/bin/dtc
export DTC_OVERLAY_TEST_EXT=~/bin/ufdt_apply_overlay
export KCFLAGS=-mno-android
DEFCONFIG="perseus_user_defconfig"

# Kernel Details
VER=".v09"

# Paths
KERNEL_DIR=`pwd`
TOOLS_DIR=/mnt/android/kernel/bin
REPACK_DIR=/mnt/android/kernel/bin/AnyKernel2
PATCH_DIR=/mnt/android/kernel/bin/AnyKernel2/patch
MODULES_DIR=/mnt/android/kernel/bin/AnyKernel2/modules/system/lib/modules
ZIP_MOVE=/mnt/android/kernel/bin/out/
ZIMAGE_DIR=${KERNEL_DIR}/out/arch/arm64/boot

# Functions
function clean_all {
		rm -rf $MODULES_DIR/*
		cd $KERNEL_DIR/out/kernel
		rm -rf $DTBIMAGE
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		echo
		make O=out clean && make O=out mrproper
}

function make_kernel {
		echo
		make O=out CONFIG_BUILD_ARM64_DT_OVERLAY=y $DEFCONFIG
		make O=out CONFIG_BUILD_ARM64_DT_OVERLAY=y $THREAD

}

function make_modules {
		rm `echo $MODULES_DIR"/*"`
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$TOOLS_DIR/dtbToolCM -2 -o $REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm64/boot/
}

function make_boot {
<< COMMENTOUT
		$TOOLS_DIR/mkbootimg \
			--kernel $ZIMAGE_DIR/Image.gz-dtb \
			--os_version "9.0.0" --os_patch_level "2018-11-01" \
			--cmdline "androidboot.hardware=qcom console=ttyMSM0,115200n8 earlycon=msm_geni_serial,0xA84000 androidboot.hardware=qcom androidboot.console=ttyMSM0 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 service_locator.enable=1 swiotlb=2048 androidboot.configfs=true firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 buildvariant=userdebug androidboot.verifiedbootstate=green androidboot.selinux=permissive" \
			--base 0x00000000 \
			--kernel_offset 0x00008000 \
			--tags_offset 0x00000100 \
			--pagesize 4096 \
			--output ${ZIP_MOVE}boot.img
COMMENTOUT

		cp -vr $ZIMAGE_DIR/Image.gz-dtb ${REPACK_DIR}/zImage
}


function make_zip {
		cd ${REPACK_DIR}
		zip -r9 `echo $AK_VER`.zip *
		mv `echo $AK_VER`.zip ${ZIP_MOVE}
		
		cd $KERNEL_DIR
}


DATE_START=$(date +"%s")


echo -e "${green}"
echo "-----------------"
echo "Making AndroPlus Kernel:"
echo "-----------------"
echo -e "${restore}"


# Vars
BASE_AK_VER="AndroPlus"
AK_VER="$BASE_AK_VER$VER"
export LOCALVERSION=~`echo $AK_VER`
export LOCALVERSION=~`echo $AK_VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=AndroPlus
export KBUILD_BUILD_HOST=andro.plus

echo

while read -p "Do you want to clean stuffs (y/N)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		break
		;;
esac
done

make_kernel
make_dtb
make_modules
make_boot
make_zip

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo