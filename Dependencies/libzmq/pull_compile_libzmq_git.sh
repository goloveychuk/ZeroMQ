#!/usr/bin/env bash


# Script adapted from https://github.com/samsoir/libzmq-ios-universal
# tried to keep things to a minimum




DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


GLOBAL_OUTDIR=${DIR}/dependencies
BUILD_DIR=${DIR}/build
LIBZMQ_DIR="${DIR}/libzmq-git"
# CURRENT_DIR=`pwd`
LIBZMQ_FILE="libzmq.a"
# LIBZMQ_UNIVERSAL_FILE="libzmq.a"
# LIBZMQ_UNIVERSAL_PREFIX="universal"
# ZMQ_BUILD_LOG_FILE=$BUILD_DIR/build.log
IOS_DEPLOY_TARGET="8.0"
OSX_DEPLOY_TARGET="10.9"
# VERSION_NUMBER="1.0.0"


if [[ -f "${BUILD_DIR}/universal/lib/${LIBZMQ_FILE}" ]]; then
exit 0;
#library already built
fi




echo "Initializing build directory..."
if [[ -d ${BUILD_DIR} ]]; then
rm -rf "${BUILD_DIR}"
fi



# mkdir -p "${BUILD_DIR}/armv7"
# mkdir -p "${BUILD_DIR}/arm64"
# mkdir -p "${BUILD_DIR}/i386"
# better create them in setenv_all

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

# export CC="$(xcrun -find -sdk ${SDK} cc)"
# export CXX="$(xcrun -find -sdk ${SDK} cxx)"
# export CPP="${CC} -E" # xcrun find cpp did not work

# after an hour trying to figure what wasn't working with CPP, just realized it was CPPFLAGS, and is not necessary to export CC or CPP

export SDKROOT
SDKROOT=$(xcrun -sdk "${SDK}" --show-sdk-path)
# export CFLAGS="-arch ${ARCH} -isysroot ${SDKROOT} -mios-version-min=${IOS_DEPLOY_TARGET}"
export CFLAGS="${CFLAGS} -arch ${ARCH}"

export CXXFLAGS="${CFLAGS}"
export CPPFLAGS="${CFLAGS}"
export LDFLAGS="${CFLAGS}"

mkdir -p "${BUILD_DIR}/${ARCH}"

}

setenv_armv7 ()
{
export CFLAGS="-mios-version-min=${IOS_DEPLOY_TARGET}"
setenv "armv7" "iphoneos" "arm-apple-darwin"
}

setenv_armv7s ()
{
export CFLAGS="-mios-version-min=${IOS_DEPLOY_TARGET}"
setenv  "armv7s" "iphoneos" "arm-apple-darwin"
}

setenv_arm64 ()
{
export CFLAGS="-mios-version-min=${IOS_DEPLOY_TARGET}"
setenv  "arm64" "iphoneos" "arm-apple-darwin"
}

setenv_i386 ()
{
export CFLAGS="-mmacosx-version-min=${OSX_DEPLOY_TARGET}"
setenv "i386" "macosx" "i386-apple-darwin"
}

setenv_x86_64 ()
{
export CFLAGS="-mmacosx-version-min=${OSX_DEPLOY_TARGET}"
setenv "x86_64" "macosx" "x86_64-apple-darwin"
}


compile_zmq ()
{
make distclean

cd "${LIBZMQ_DIR}" || exit

${LIBZMQ_DIR}/autogen.sh

cd "${DIR}" || exit


"${LIBZMQ_DIR}/configure" --disable-dependency-tracking \
--enable-static --disable-shared \
--host=${HOST} \
--prefix="${BUILD_DIR}/${ARCH}" --without-libsodium

make
make install
make clean
}


rm -rf "${LIBZMQ_DIR}"

echo "Cloning libzmq from source https://github.com/zeromq/libzmq.git"

git clone "https://github.com/zeromq/libzmq.git" "${LIBZMQ_DIR}"


echo "running autogen.sh"

"${LIBZMQ_DIR}"/autogen.sh


echo "Compiling libzmq for armv7..."
setenv_armv7
compile_zmq

echo "Compiling libzmq for armv7s..."
setenv_armv7s
compile_zmq

echo "Compiling libzmq for arm64..."
setenv_arm64
compile_zmq

echo "Compiling libzmq for i386..."
setenv_i386
compile_zmq

echo "Compiling libzmq for x86_64..."
setenv_x86_64
compile_zmq


echo "Creating universal static library for armv7, armv7s, arm64, i386, x86_64"

mkdir -p "${BUILD_DIR}/${LIBZMQ_UNIVERSAL_PREFIX}/lib"

for arch in armv7 armv7s arm64 i386 x86_64 ; do
lipo_input+=("${BUILD_DIR}/${arch}/lib/${LIBZMQ_FILE}")
done


mkdir -p "${BUILD_DIR}/universal/lib/"

lipo -create ${lipo_input[*]} -output "${BUILD_DIR}/universal/lib/${LIBZMQ_FILE}"


echo "Copying libzmq headers into universal library..."

mkdir -p "${BUILD_DIR}/${LIBZMQ_UNIVERSAL_PREFIX}/include"
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


cat << EOF

Finished compiling libzmq as a static library for iOS.

Universal library can be found in build/universal;
"lib" folder contains "libzmq.a" static library
"include" folder contains headers

To use in your project follow linking instructions
available on the iOS zeromq page
http://www.zeromq.org/build:iphone

EOF
