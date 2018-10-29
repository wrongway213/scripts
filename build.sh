#!/usr/bin/env bash
SECONDS=0
TEXTRESET=$(tput sgr0)
TEXTGREEN=$(tput setaf 2)
TEXTRED=$(tput setaf 1)

echo "${TEXTRED}NO Version number specified. Naming zips as TEST ${TEXTRESET}"

# Export compiler name
export COMPILER_NAME="CLANG-7.0.2"

if [ -z ${KRIEG_SCRIPT+x} ]; then
	cd ..
fi
REPO_ROOT=`pwd`

if [ -z "$1" ]
    then
		VERSION="TEST"
	else
		VERSION="$1"
fi

# Clang and GCC paths
CLANG=${REPO_ROOT}/ToolChains/linux-x86/clang-r328903/bin/clang
CROSS_COMPILE=${REPO_ROOT}/ToolChains/aarch64-linux-android-4.9/bin/aarch64-linux-android-

process_build () {
	if [ $1 = "nontreble" ]; then
		echo "${TEXTGREEN}Building for non-treble. Reverting vendor parition mounting in DTSI${TEXTRESET}"
		git am ${REPO_ROOT}/scripts/patches/0001-Revert-oneplus5-custom-mount-vendor-partition.patch
	else
		echo "${TEXTGREEN}Building for treble${TEXTRESET}"
	fi
	
	make O=out ARCH=arm64 krieg_defconfig
	make -j$(nproc --all) O=out \
						  ARCH=arm64 \
						  CC="${CLANG}" \
						  CLANG_TRIPLE=aarch64-linux-gnu- \
						  CROSS_COMPILE="${CROSS_COMPILE}" \
						  KBUILD_COMPILER_STRING="$(${CLANG}  --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')" \

	# Move custom Image  to AK
	cp ${REPO_ROOT}/OP5-OP5T/out/arch/arm64/boot/Image.gz-dtb ${REPO_ROOT}/AnyKernelBase/kernels/custom/Image.gz-dtb

	# Make zip.
	cd ${REPO_ROOT}/AnyKernelBase
	.zip -r9 ${REPO_ROOT}/Krieg-EAS-$1-V-$VERSION.zip * -x README Krieg-EAS-$1-V-$VERSION.zip

	# Clean up at the end as well for good measure
	rm -rf ${REPO_ROOT}/OP5-OP5T/out
	rm -rf ${REPO_ROOT}/AnyKernelBase/kernels/

	# Back to Source
	cd ${REPO_ROOT}/OP5-OP5T
	
	if [ $1 = "nontreble" ]; then
		echo "${TEXTGREEN}Non-Treble Build Complete${TEXTRESET}"
		git reset --hard HEAD~1
	else
		echo "${TEXTGREEN}Non-Treble Build Complete${TEXTRESET}"
	fi
	
}


# Build "custom" kernel
rm -rf ${REPO_ROOT}/OP5-OP5T/out/
mkdir -p ${REPO_ROOT}/AnyKernelBase/kernels/custom
mkdir -p ${REPO_ROOT}/AnyKernelBase/kernels/oos

cd ${REPO_ROOT}/OP5-OP5T

process_build treble
process_build nontreble

duration=$SECONDS
echo "${TEXTGREEN}Builds complete. The zips can be found at: ${REPO_ROOT}${TEXTRESET}"
echo "${TEXTGREEN}Total time taken: $(($duration / 60)):$(($duration % 60))${TEXTRESET}"
