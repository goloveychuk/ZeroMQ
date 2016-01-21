#!/usr/bin/env bash


# Script adapted from https://github.com/samsoir/libzmq-ios-universal
# tried to keep things to a minimum




DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


GLOBAL_OUTDIR=${DIR}/dependencies
BUILD_DIR=${DIR}/build

LIBZMQ_DIR="${DIR}/libzmq-git"
LIBZMQ_FILE="libzmq.a"

IOS_DEPLOY_TARGET="8.0"
OSX_DEPLOY_TARGET="10.9"


if [[ -f "${DIR}/libzmq-ios.a" ]]; then
exit 0;
#library already built
fi




echo "Initializing build directory..."
if [[ -d ${BUILD_DIR} ]]; then
rm -rf "${BUILD_DIR}"
fi


echo "Initializing dependency directory..."
if [[ -d ${GLOBAL_OUTDIR} ]]; then
rm -rf "${GLOBAL_OUTDIR}"
fi

mkdir -p "${GLOBAL_OUTDIR}/include" "${GLOBAL_OUTDIR}/lib"




setenv ()
{
export ARCH=$1
export SDK=$2
export HOST=$3


export SDKROOT
SDKROOT=$(xcrun -sdk "${SDK}" --show-sdk-path)

export CFLAGS="${CFLAGS} -arch ${ARCH}"

export CXXFLAGS="${CFLAGS}"
export CPPFLAGS="${CFLAGS}"
export LDFLAGS="${CFLAGS}"

mkdir -p "${BUILD_DIR}/${SDK}-${ARCH}"

}




setenv_ios ()
{
export CFLAGS="-mios-version-min=${IOS_DEPLOY_TARGET}"
setenv $1 $2 $3
}

setenv_osx ()
{
export CFLAGS="-mmacosx-version-min=${OSX_DEPLOY_TARGET}"
setenv $1 $2 $3
}

compile_zmq ()
{
make distclean



"${LIBZMQ_DIR}/configure" --disable-dependency-tracking \
--enable-static --disable-shared \
--host=${HOST} \
--prefix="${BUILD_DIR}/${SDK}-${ARCH}" --without-libsodium

make
make install
make clean
}


rm -rf "${LIBZMQ_DIR}"

echo "Cloning libzmq from source https://github.com/zeromq/libzmq.git"

git clone "https://github.com/zeromq/libzmq.git" "${LIBZMQ_DIR}"



cd "${LIBZMQ_DIR}" || exit

${LIBZMQ_DIR}/autogen.sh

cd "${DIR}" || exit


echo "Compiling libzmq for iphoneos/iphonesimulator"
echo "============================================="
# ios and mac osx should be compiled in different files
# https://karp.id.au/post/xcode_7_linker_rules/

echo "Compiling libzmq for armv7..."
setenv_ios "armv7" "iphoneos" "arm-apple-darwin"
compile_zmq

echo "Compiling libzmq for armv7s..."
setenv_ios "armv7s" "iphoneos" "arm-apple-darwin"
compile_zmq

echo "Compiling libzmq for arm64..."
setenv_ios "arm64" "iphoneos" "arm-apple-darwin"
compile_zmq

echo "Compiling libzmq for i386..."
setenv_ios "i386" "iphonesimulator" "i386-apple-darwin"
compile_zmq

echo "Compiling libzmq for x86_64..."
setenv_ios "x86_64" "iphonesimulator" "x86_64-apple-darwin"
compile_zmq


echo "Creating fat static library for iphoneos/iphonesimulator"

lipo_input+=("${BUILD_DIR}/iphoneos-armv7/lib/${LIBZMQ_FILE}")
lipo_input+=("${BUILD_DIR}/iphoneos-armv7s/lib/${LIBZMQ_FILE}")
lipo_input+=("${BUILD_DIR}/iphoneos-arm64/lib/${LIBZMQ_FILE}")
lipo_input+=("${BUILD_DIR}/iphonesimulator-i386/lib/${LIBZMQ_FILE}")
lipo_input+=("${BUILD_DIR}/iphonesimulator-x86_64/lib/${LIBZMQ_FILE}")

mkdir -p "${BUILD_DIR}/universal-ios/"

lipo -create ${lipo_input[*]} -output "${BUILD_DIR}/universal-ios/${LIBZMQ_FILE}"



echo "Compiling libzmq for macosx"
echo "==========================="

echo "Compiling libzmq for i386..."
setenv_osx "i386" "macosx" "i386-apple-darwin"
compile_zmq

echo "Compiling libzmq for x86_64..."
setenv_osx "x86_64" "macosx" "x86_64-apple-darwin"
compile_zmq


echo "Creating fat static library for macosx"

lipo_input=( )
lipo_input+=("${BUILD_DIR}/macosx-i386/lib/${LIBZMQ_FILE}")
lipo_input+=("${BUILD_DIR}/macosx-x86_64/lib/${LIBZMQ_FILE}")

mkdir -p "${BUILD_DIR}/universal-osx/"

lipo -create ${lipo_input[*]} -output "${BUILD_DIR}/universal-osx/${LIBZMQ_FILE}"







echo "Copying libzmq headers into universal library..."

mkdir -p "${BUILD_DIR}/universal"
cp -R "${LIBZMQ_DIR}/include" "${BUILD_DIR}/universal"







echo "Tidying up..."
rm -rf builds
rm -rf config.*
rm -rf dependencies
rm -rf doc
rm -rf foreign
rm -f libtool
rm -f Makefile
rm -rf perf
rm -rf src
rm -rf tests
rm -rf packaging
rm -rf tools


cp ${DIR}/build/universal/include/zmq.h ${DIR}
cp ${DIR}/build/universal/include/zmq_utils.h ${DIR}
cp ${DIR}/build/universal-ios/libzmq.a ${DIR}/libzmq-ios.a
cp ${DIR}/build/universal-osx/libzmq.a ${DIR}/libzmq-osx.a

