#!/bin/bash  

WORK_DIRECTORY="$HOME/android/tilapia-aosp-7.1"
REPO_DIRECTORY='.repo'
REPO_SYNC_THREADS=$(nproc --all)
#REPO_SYNC_THREADS="1"
AOSP_REVISION="ads-7.1.0"
REPO_INIT_FLAGS="--depth=1 --no-clone-bundle"
#REPO_INIT_FLAGS="--no-clone-bundle"
REPO_SYNC_FLAGS="--no-tags --no-clone-bundle"
#REPO_SYNC_FLAGS="--no-clone-bundle"

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
  echo "### initialising AOSP repo for first time..."
  repo init -u https://github.com/AndDiSa/platform_manifest-Grouper-AOSP.git -b $AOSP_REVISION $REPO_INIT_FLAGS
  #repo init -u https://github.com/fidoedidoe/platform_manifest-Grouper-AOSP.git -b $AOSP_REVISION $REPO_INIT_FLAGS
else
  echo "### LOS Repo exists..."
  echo "### step 1/1: reverting all local AOSP modifications..."
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
repo sync --quiet --force-broken --jobs="$REPO_SYNC_THREADS" $REPO_SYNC_FLAGS

#PROMPT=""
#read -r -p "### (3/6) Continue and apply device specific patch <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
#echo
#if [ -z "$PROMPT" ]; then
#  PROMPT="Y"
#fi
#if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
#  echo "### Response: '$PROMPT', exiting!"
#  exit 1
#fi

#Patch script  - nolonger needed
#cd "$WORK_DIRECTORY"/build || exit
#patch -p 1 < ../.repo/manifests/build.patch
#cd "$WORK_DIRECTORY"/frameworks/av || exit
#patch -p 1 < ../../.repo/manifests/frameworks_av.patch
#cd "$WORK_DIRECTORY"/frameworks/base || exit
#patch -p 1 < ../../.repo/manifests/frameworks_base.patch
#cd "$WORK_DIRECTORY"/frameworks/native || exit
#patch -p 1 < ../../.repo/manifests/frameworks_native.patch
#cd "$WORK_DIRECTORY"/hardware/ril || exit
#patch -p 1 < ../../.repo/manifests/hardware_ril.patch
##cd "$WORK_DIRECTORY"/packages/apps/Music || exit
##patch -p 1 < ../../../.repo/manifests/packages_apps_music.patch
#cd "$WORK_DIRECTORY"/system/core || exit
#patch -p 1 < ../../.repo/manifests/system_core.patch
#cd "$WORK_DIRECTORY"/system/sepolicy || exit
#patch -p 1 < ../../.repo/manifests/system_sepolicy.patch

#cd "$WORK_DIRECTORY" || exit


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
