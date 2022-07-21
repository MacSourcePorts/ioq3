# game/app specific values
# note that for ioq3 some of these values are not used since it handles bundling differently. 
export APP_VERSION=`grep '^VERSION=' Makefile | sed -e 's/.*=\(.*\)/\1/'`
export ICONSDIR="."
export ICONSFILENAME="quake3_flat"
export PRODUCT_NAME="ioquake3"
export EXECUTABLE_NAME="ioquake3"
export PKGINFO="APPLIOQ3"
export COPYRIGHT_TEXT="QUAKE III ARENA Copyright © 1999-2000 id Software, Inc. All rights reserved."

# constants
export BUILT_PRODUCTS_DIR="release"
export WRAPPER_NAME="${PRODUCT_NAME}.app"
export CONTENTS_FOLDER_PATH="${WRAPPER_NAME}/Contents"
export EXECUTABLE_FOLDER_PATH="${CONTENTS_FOLDER_PATH}/MacOS"
export UNLOCALIZED_RESOURCES_FOLDER_PATH="${CONTENTS_FOLDER_PATH}/Resources"
export ICONS="${ICONSFILENAME}.icns"
export BUNDLE_ID="com.macsourceports.${PRODUCT_NAME}"

unset X86_64_SDK
unset X86_64_CFLAGS
unset X86_64_MACOSX_VERSION_MIN
unset ARM64_SDK
unset ARM64_CFLAGS
unset ARM64_MACOSX_VERSION_MIN

X86_64_MACOSX_VERSION_MIN="10.7"
ARM64_MACOSX_VERSION_MIN="11.0"

echo "Building X86_64 Client/Dedicated Server"
echo "Building ARM64 Client/Dedicated Server"
echo

if [ "$1" == "" ]; then
	echo "Run script with a 'notarize' flag to perform signing and notarization."
fi

# For parallel make on multicore boxes...
NCPU=`sysctl -n hw.ncpu`

# x86_64 client and server
if [ -d build/release-release-x86_64 ]; then
rm -rf build/release-darwin-x86_64
fi
(ARCH=x86_64 CFLAGS=$X86_64_CFLAGS MACOSX_VERSION_MIN=$X86_64_MACOSX_VERSION_MIN make -j$NCPU) || exit 1;

echo;echo

# arm64 client and server
if [ -d build/release-release-arm64 ]; then
rm -rf build/release-darwin-arm64
fi
(ARCH=arm64 CFLAGS=$ARM64_CFLAGS MACOSX_VERSION_MIN=$ARM64_MACOSX_VERSION_MIN make -j$NCPU) || exit 1;

echo

# use the following shell script to build a universal 2 application bundle
export MACOSX_DEPLOYMENT_TARGET="10.7"
export MACOSX_DEPLOYMENT_TARGET_X86_64="$X86_64_MACOSX_VERSION_MIN"
export MACOSX_DEPLOYMENT_TARGET_ARM64="$ARM64_MACOSX_VERSION_MIN"
export MACOSX_BUNDLE_TYPE="universal2"

if [ -d build/release-darwin-universal2 ]; then
	rm -r build/release-darwin-universal2
fi

# ioq3 handles its own app bundling and lipo'ing so we do this
# instead of calling "../MSPScripts/build_app_bundle.sh"
"./make-macosx-app.sh" release

if [ -d "${BUILT_PRODUCTS_DIR}" ]; then
rm -r "${BUILT_PRODUCTS_DIR}"
fi
mkdir "${BUILT_PRODUCTS_DIR}"
cp -R build/release-darwin-universal2/"${WRAPPER_NAME}" "${BUILT_PRODUCTS_DIR}"

export ENTITLEMENTS_FILE="misc/xcode/ioquake3/ioquake3.entitlements"

"../MSPScripts/sign_and_notarize.sh" "$1" entitlements