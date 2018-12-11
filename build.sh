#!/usr/bin/env bash
SECONDS=0
TEXTRESET=$(tput sgr0)
TEXTGREEN=$(tput setaf 2)
TEXTRED=$(tput setaf 1)
BUILD_SUCCESS="999"

export COMPILER_NAME="CLANG-8.0.4"
# Export compiler name

if [ -z ${KRIEG_SCRIPT+x} ]; then
	cd ..
fi
REPO_ROOT=`pwd`

# Clang and GCC paths
CLANG=${REPO_ROOT}/Toolchains/linux-x86/clang-r344140b/bin/clang
if [ ${USE_CCACHE:-"0"} = "1" ]; then
    CLANG="ccache ${CLANG}"
fi
CROSS_COMPILE=${REPO_ROOT}/Toolchains/aarch64-linux-android-4.9/bin/aarch64-linux-android-

process_build () {
	mkdir -p ${REPO_ROOT}/AnyKernelBase/kernels/custom/$1 ${REPO_ROOT}/AnyKernelBase/kernels/oos/$1

	if [ $1 = "nontreble" ]; then
		echo "${TEXTGREEN}Building for $1. Reverting vendor parition mounting in DTSI${TEXTRESET}"
		git am ${REPO_ROOT}/scripts/patches/0001-Revert-oneplus5-custom-mount-vendor-partition.patch
	else
		echo "${TEXTGREEN}Building for $1${TEXTRESET}"
	fi
	
	make O=out ARCH=arm64 krieg_defconfig
	make -j$(nproc --all) O=out \
						  ARCH=arm64 \
						  CC="${CLANG}" \
						  CLANG_TRIPLE=aarch64-linux-gnu- \
						  CROSS_COMPILE="${CROSS_COMPILE}" \
						  KBUILD_COMPILER_STRING="$(${CLANG}  --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')" \

  # Check exit code of the make command
  BUILD_SUCCESS=$?
    
  if [ $BUILD_SUCCESS -ne 0 ]; then
		echo "${TEXTRED} Build for - $1 - failed! Aborting further processing!${TEXTRESET}"
	else
		# Move custom Image  to AK2
		cp -f ${REPO_ROOT}/OP5-OP5T/out/arch/arm64/boot/Image.gz-dtb ${REPO_ROOT}/AnyKernelBase/kernels/custom/$1/Image.gz-dtb
    # Back to Source
    cd ${REPO_ROOT}/OP5-OP5T    
    echo "${TEXTGREEN}$1 Build Complete${TEXTRESET}"
	fi
	
  # Clean up at the end as well for good measure
  rm -rf ${REPO_ROOT}/OP5-OP5T/out
  [ "$1" == "nontreble" ] && git reset --hard HEAD~1
}

# Clean up if anything is remaining.
rm -rf ${REPO_ROOT}/OP5-OP5T/out

# Ignore upper/lower case
case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
  "all")
    ZIPNAME=""
    process_build treble
    [ $BUILD_SUCCESS -ne 0 ] && break
    process_build nontreble
    ;;
  "treble")
    ZIPNAME="-treble"
    process_build treble
    ;;
  "nontreble")
    ZIPNAME="-nontreble"
    process_build nontreble
    ;;
  *) echo -e "Please enter an argument\nValid arguments are: all treble nontreble"
    ;;
esac

if [ $BUILD_SUCCESS -eq 0 ]; then
  # Make zip and cleanup
  cd ${REPO_ROOT}/AnyKernelBase
  zip -r9 ${REPO_ROOT}/Krieg-EAS$ZIPNAME-V-$VERSION.zip * -x README Krieg-EAS$ZIPNAME-V-$VERSION.zip
  rm -rf ${REPO_ROOT}/AnyKernelBase/kernels/
  
	duration=$SECONDS
	echo "${TEXTGREEN}Builds complete. The zips can be found at: ${REPO_ROOT}${TEXTRESET}"
	echo "${TEXTGREEN}Total time taken: $(($duration / 60)):$(($duration % 60))${TEXTRESET}"
fi
