#!/bin/bash  

WORK_DIRECTORY="$HOME/android/tilapia-aosp-7.1"
REPO_DIRECTORY='.repo'
REPO_SYNC_THREADS=$(nproc --all)
#GITHUB_USER="AndDiSa"
GITHUB_USER="fidoedidoe"
#GITHUB_BRANCH="ads-7.1.0"
GITHUB_BRANCH="test-7.1.0"
REPO_INIT_FLAGS="--depth=1 --no-clone-bundle"
REPO_SYNC_FLAGS="--quiet --force-sync --no-tags --no-clone-bundle"
#REPO_SYNC_FLAGS="--quiet --force-sync force-broken --no-tags --no-clone-bundle"
SLEEP_DURATION="1"

PROMPT=""
read -r -p "### (1/4) Start Repo Sync and Build process, first 'repo init' will take hours <Y/n>? (automatically continues unprompted after 5 seconds): " -t 5 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

#Ensure working directory exists
mkdir -p "$WORK_DIRECTORY"

# Change to working directory
cd "$WORK_DIRECTORY" || exit
	

if [ ! -d "$WORK_DIRECTORY/$REPO_DIRECTORY" ]; then
  echo "### initialising github repo for first time..."
  repo init $REPO_INIT_FLAGS -u https://github.com/$GITHUB_USER/platform_manifest-Grouper-AOSP.git -b $GITHUB_BRANCH
else
  echo "### github Repo exists..."
  echo "### step 1/1: reverting all local  modifications..."
  repo forall -vc "git reset --hard ; git clean -fdx" --quiet
  echo "### step 1 - 1: complete"
fi

PROMPT=""
read -r -p "### (2/4) Continue and sync repo <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

echo "### sync repo with $REPO_SYNC_THREADS threads..."
repo sync --jobs="$REPO_SYNC_THREADS" $REPO_SYNC_FLAGS

PROMPT=""
read -r -p "### (3/6) Continue and apply device specific patch <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

#Patch script  - not needed if using forked repos
cd "$WORK_DIRECTORY"/bionic || exit
echo "### applying patch .repo/manifests/bionic.patch"
patch -p 1 < ../.repo/manifests/bionic.patch
sleep $SLEEP_DURATION

cd "$WORK_DIRECTORY"/build || exit
echo "### applying patch .repo/manifests/build.patch"
patch -p 1 < ../.repo/manifests/build.patch
sleep $SLEEP_DURATION

cd "$WORK_DIRECTORY"/external/aac || exit
echo "### applying patch .repo/manifests/external_aac.patch"
patch -p 1 < ../../.repo/manifests/external_aac.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/android-clat || exit
echo "### applying patch .repo/manifests/external_android_clat.patch"
patch -p 1 < ../../.repo/manifests/external_android_clat.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/apache-http || exit
echo "### applying patch .repo/manifests/external_apache-http.patch"
patch -p 1 < ../../.repo/manifests/external_apache-http.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/chromium-libpac || exit
echo "### applying patch .repo/manifests/external_chromium_libpac.patch"
patch -p 1 < ../../.repo/manifests/external_chromium_libpac.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/curl || exit
echo "### applying patch .repo/manifests/external_curl.patch"
patch -p 1 < ../../.repo/manifests/external_curl.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/e2fsprogs || exit
echo "### applying patch .repo/manifests/external_e2fsprogs.patch"
patch -p 1 < ../../.repo/manifests/external_e2fsprogs.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/libavc || exit
echo "### applying patch .repo/manifests/external_libavc.patch"
patch -p 1 < ../../.repo/manifests/external_libavc.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/libdrm || exit
echo "### applying patch .repo/manifests/external_libdrm.patch"
patch -p 1 < ../../.repo/manifests/external_libdrm.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/libhevc || exit
echo "### applying patch ./repo/manifests/external_libhevc.patch"
patch -p 1 < ../../.repo/manifests/external_libhevc.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/libmpeg2 || exit
echo "### applying patch .repo/manifests/external_libmpeg2.patch"
patch -p 1 < ../../.repo/manifests/external_libmpeg2.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/libnfc-nci || exit
echo "### applying patch .repo/manifests/external_libnfc-nci.patch"
patch -p 1 < ../../.repo/manifests/external_libnfc-nci.patch
sleep $SLEEP_DURATION
# ######################################################################
# This next patch fails, it has already need applied in AndDiSa's repo!!
# ######################################################################
#cd "$WORK_DIRECTORY"/external/libnfc-nxp || exit
#echo "### applying patch .repo/manifests/external_libnfc-nxp.patch"
#patch -p 1 < ../../.repo/manifests/external_libnfc-nxp.patch
#sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/libvpx || exit
echo "### applying patch .repo/manifests/external_libvpx.patch"
patch -p 1 < ../../.repo/manifests/external_libvpx.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/neven || exit
echo "### applying patch .repo/manifests/external_neven.patch"
patch -p 1 < ../../.repo/manifests/external_neven.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/opencv || exit
echo "### applying patch .repo/manifests/external_opencv.patch"
patch -p 1 < ../../.repo/manifests/external_opencv.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/skia || exit
echo "### applying patch .repo/manifests/external_skia.patch"
patch -p 1 < ../../.repo/manifests/external_skia.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/sonivox || exit
echo "### applying patch .repo/manifests/external_sonivox.patch"
patch -p 1 < ../../.repo/manifests/external_sonivox.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/sqlite || exit
echo "### applying patch .repo/manifests/external_sqlite.patch"
patch -p 1 < ../../.repo/manifests/external_sqlite.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/svox || exit
echo "### applying patch .repo/manifests/external_svox.patch"
patch -p 1 < ../../.repo/manifests/external_svox.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/tremolo || exit
echo "### applying patch .repo/manifests/external_tremolo.patch"
patch -p 1 < ../../.repo/manifests/external_tremolo.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/external/wpa_supplicant_8 || exit
echo "### applying patch .repo/manifests/external_wpa_supplicant_8.patch"
patch -p 1 < ../../.repo/manifests/external_wpa_supplicant_8.patch
sleep $SLEEP_DURATION

cd "$WORK_DIRECTORY"/frameworks/av || exit
echo "### applying patch .repo/manifests/frameworks_av.patch"
patch -p 1 < ../../.repo/manifests/frameworks_av.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/frameworks/base || exit
echo "### applying patch .repo/manifests/frameworks_base.patch"
patch -p 1 < ../../.repo/manifests/frameworks_base.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/frameworks/ex || exit
echo "### applying patch .repo/manifests/frameworks_ex.patch"
patch -p 1 < ../../.repo/manifests/frameworks_ex.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/frameworks/minikin || exit
echo "### applying patch .repo/manifests/frameworks_minikin.patch"
patch -p 1 < ../../.repo/manifests/frameworks_minikin.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/frameworks/native || exit
echo "### applying patch .repo/manifests/frameworks_native.patch"
patch -p 1 < ../../.repo/manifests/frameworks_native.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/frameworks/opt/net/wifi || exit
echo "### applying patch .repo/manifests/frameworks_op_net_wifi.patch"
patch -p 1 < ../../../../.repo/manifests/frameworks_op_net_wifi.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/frameworks/support || exit
echo "### applying patch .repo/manifests/frameworks_support.patch"
patch -p 1 < ../../.repo/manifests/frameworks_support.patch
sleep $SLEEP_DURATION

cd "$WORK_DIRECTORY"/hardware/broadcom/wlan || exit
echo "### applying patch .repo/manifests/hardware_broadcom_wlan.patch"
patch -p 1 < ../../../.repo/manifests/hardware_broadcom_wlan.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/hardware/libhardware || exit
echo "### applying patch .repo/manifests/hardware_libhardware.patch"
patch -p 1 < ../../.repo/manifests/hardware_libhardware.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/hardware/qcom/audio || exit
echo "### applying patch .repo/manifests/hardware_qcom_audio.patch"
patch -p 1 < ../../../.repo/manifests/hardware_qcom_audio.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/hardware/ril || exit
echo "### applying patch .repo/manifests/hardware_ril.patch"
patch -p 1 < ../../.repo/manifests/hardware_ril.patch
sleep $SLEEP_DURATION

cd "$WORK_DIRECTORY"/libcore || exit
echo "### applying patch .repo/manifests/libcore.patch"
patch -p 1 < ../.repo/manifests/libcore.patch
sleep $SLEEP_DURATION

cd "$WORK_DIRECTORY"/packages/apps/Email || exit
echo "### applying patch .repo/manifests/packages_apps_email.patch"
patch -p 1 < ../../../.repo/manifests/packages_apps_email.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/packages/apps/Messaging || exit
echo "### applying patch .repo/manifests/packages_apps_messaging.patch"
patch -p 1 < ../../../.repo/manifests/packages_apps_messaging.patch
sleep $SLEEP_DURATION
######################################################################
# The source directory for this patch doesn't exist, skipping patch ##
######################################################################
#cd "$WORK_DIRECTORY"/packages/apps/Music || exit
#echo "### applying patch .repo/manifests/packages_apps_music.patch"
#patch -p 1 < ../../../.repo/manifests/packages_apps_music.patch
#sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/packages/apps/Nfc || exit
echo "### applying patch .repo/manifests/packages_apps_nfc.patch"
patch -p 1 < ../../../.repo/manifests/packages_apps_nfc.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/packages/apps/Settings || exit
echo "### applying patch .repo/manifests/packages_apps_settings.patch"
patch -p 1 < ../../../.repo/manifests/packages_apps_settings.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/packages/apps/UnifiedEmail || exit
echo "### applying patch .repo/manifests/packages_apps_unifiedemail.patch"
patch -p 1 < ../../../.repo/manifests/packages_apps_unifiedemail.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/packages/providers/DownloadProvider || exit
echo "### applying patch .repo/manifests/packages_provider_downloadprovider.patch"
patch -p 1 < ../../../.repo/manifests/packages_provider_downloadprovider.patch
sleep $SLEEP_DURATION

####################################################################
# Next Patch appears to have been applied (unlegacy project repo) ##
####################################################################
#cd "$WORK_DIRECTORY"/system/bt ||dd exit
#echo "### applying patch .repo/manifests/system_bt.patch"
#patch -p 1 < ../../.repo/manifests/system_bt.patch
#sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/system/core ||dd exit
echo "### applying patch .repo/manifests/system_core.patch"
patch -p 1 < ../../.repo/manifests/system_core.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/system/media ||dd exit
echo "### applying patch .repo/manifests/system_media.patch"
patch -p 1 < ../../.repo/manifests/system_media.patch
sleep $SLEEP_DURATION
###################################
# Zero byte patch file, skipping ##
###################################
#cd "$WORK_DIRECTORY"/system/security ||dd exit
#echo "### applying patch .repo/manifests/system_security.patch"
#patch -p 1 < ../../.repo/manifests/system_security.patch
#sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/system/sepolicy || exit
echo "### applying patch .repo/manifests/system_sepolicy.patch"
patch -p 1 < ../../.repo/manifests/system_sepolicy.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/system/vold ||dd exit
echo "### applying patch .repo/manifests/system_vold.patch"
patch -p 1 < ../../.repo/manifests/system_vold.patch
sleep $SLEEP_DURATION
cd "$WORK_DIRECTORY"/system/update_engine ||dd exit
echo "### applying patch .repo/manifests/update_engine.patch"
patch -p 1 < ../../.repo/manifests/update_engine.patch
echo "### End of patches!"

cd "$WORK_DIRECTORY" || exit


PROMPT=""
read -r -p "### (3/4) Continue and prepare device specific code <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

echo "### prepare device specific code..."
source build/envsetup.sh
lunch aosp_tilapia-userdebug

echo "### running croot..."
croot

echo "### set environment var to stop issues with prebuilts/misc/.../flex"
export LC_ALL=C

echo "### remove previous build output"
rm -rf out/*

cd "$WORK_DIRECTORY" || exit


PROMPT=""
read -r -p "### (4/4) Continue with ROM build process (this step can take more than an hour depending on CC_CACHE) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

echo "### running 'make otapackage with $REPO_SYNC_THREADS threads'..."
make -j$REPO_SYNC_THREADS otapackage

echo "### End of Build Script! ###"
