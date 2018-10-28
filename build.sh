# Export compiler name
export COMPILER_NAME="CLANG-7.0.2"
cd ..
REPO_ROOT=`pwd`

# Clang and GCC paths
CLANG=${REPO_ROOT}/ToolChains/linux-x86/clang-r328903/bin/clang
CROSS_COMPILE=${REPO_ROOT}/ToolChains/aarch64-linux-android-4.9/bin/aarch64-linux-android-

# Build "custom" kernel
rm -rf ${REPO_ROOT}/OP5-OP5T/out/

cd ${REPO_ROOT}/OP5-OP5T

make O=out ARCH=arm64 krieg_defconfig
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC="${CLANG}" \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE="${CROSS_COMPILE}" \
                      KBUILD_COMPILER_STRING="$(${CLANG}  --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"

# Move custom Image  to AK
mv ${REPO_ROOT}/OP5-OP5T/out/arch/arm64/boot/Image.gz-dtb ${REPO_ROOT}/AnyKernelBase/kernels/custom

# Make zip.
cd ${REPO_ROOT}/AnyKernelBase
zip -r9 ${REPO_ROOT}/Krieg-EAS-TREBLE-V-.zip * -x README Krieg-EAS-TREBLE-V-.zip

# Clean up at the end as well for good measure
rm -rf ${REPO_ROOT}/OP5-OP5T/out

# Back to Source
cd ${REPO_ROOT}/OP5-OP5T

