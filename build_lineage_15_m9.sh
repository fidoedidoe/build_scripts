#!/bin/bash  

INSERT_TEXT='<?xml version="1.0" encoding="UTF-8"?>\n <manifest>\n  <project name="LineageOS/android_device_htc_himaul" path="device/htc/himaul" remote="github" />\n  <project name="LineageOS/android_device_htc_himawl" path="device/htc/himawl" remote="github" />\n  <project name="LineageOS/android_device_htc_hima-common" path="device/htc/hima-common" remote="github" />\n  <project name="LineageOS/android_kernel_htc_msm8994" path="kernel/htc/msm8994" remote="github" />\n  <project name="LineageOS/android_device_qcom_common" path="device/qcom/common" remote="github" />\n  <project name="LineageOS/android_packages_resources_devicesettings" path="packages/resources/devicesettings" remote="github" />\n  <project name="TheMuppets/proprietary_vendor_htc" path="vendor/htc" remote="github" />\n</manifest>\n'

WORK_DIRECTORY="$HOME/android/rom"
SAMPLE_REPO_DIRECTORY='frameworks'
LOCAL_MANIFESTS_DIRECTORY='.repo/local_manifests'
LOCAL_MANIFESTS="roomservice.xml"
REPO_SYNC_THREADS=16
CLEAN=0
LOS_REVISION="lineage-15.0"

PROMPT=""
read -r -p "Start Repo Sync and Build process, first 'repo init' will take hours <Y/n>? (automatically continues unpromted after 5 seconds): " -t 5 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

#Ensure working directory exists
mkdir -p "$WORK_DIRECTORY"

# Change to working directory
cd "$WORK_DIRECTORY" || exit
	
if [ ! -d "$SAMPLE_REPO_DIRECTORY" ]; then
  echo "initialising repo for first time..."
  mkdir -p "$WORK_DIRECTORY"/"$LOCAL_MANIFESTS_DIRECTORY"
  rm -rf "$WORK_DIRECTORY"/"$LOCAL_MANIFESTS_DIRECTORY"/*
  repo init -u https://github.com/LineageOS/android.git -b $LOS_REVISION
else
  echo "repo exists, reverting all local modifications..."
  repo forall -vc "git reset --hard" --quiet
  CLEAN=1
fi

PROMPT=""
read -r -p "Continue and sync repo <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

echo "sync repo..."
repo sync -c --quiet --jobs="$REPO_SYNC_THREADS"

if [ "$CLEAN" -eq "0" ]; then
  echo "create local_manifests and rerunning repo sync..."           
  mkdir -p "$WORK_DIRECTORY"/"$LOCAL_MANIFESTS_DIRECTORY"
  echo -e "$INSERT_TEXT" > "$WORK_DIRECTORY"/"$LOCAL_MANIFESTS_DIRECTORY"/"$LOCAL_MANIFESTS"
  chmod ug+x "$WORK_DIRECTORY"/"$LOCAL_MANIFESTS_DIRECTORY"/"$LOCAL_MANIFESTS"
  repo sync -c --quiet --jobs="$REPO_SYNC_THREADS"
fi

PROMPT=""
read -r -p "Continue and prepare device specific code <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

echo "prepare device specific code..."
. build/envsetup.sh

if [ "$CLEAN" -eq "1" ]; then
  echo "clearing old build output"           
  mka clobber
fi


echo "running repopick (uncommitted changes)..."
# From: https://review.lineageos.org/#/q/project:LineageOS/android_device_htc_hima-common
repopick 194359 195049 195889 195899 194361 196446 195943 195944
# From: https://review.lineageos.org/#/q/project:LineageOS/android_hardware_qcom_audio
repopick 187514 190166 190165

echo "git fetch flyhalf205 repo and cherry pick..."
cd "$WORK_DIRECTORY"/vendor/htc/ || exit
git fetch https://github.com/Flyhalf205/proprietary_vendor_htc.git lineage-15.0
git cherry-pick a01cd415790266b49ba3bc6c87e4d499eabd8632
git cherry-pick dbce6a0c8364fefa447aa98c22e6da08c94c55b3
git cherry-pick c6c1494596da5e3ff95b3a708b79c7ed70a12a82

#echo "git fetch Mirnek and cherry pick..."
#cd "$WORK_DIRECTORY"/device/htc/hima-common/
#git fetch https://github.com/Mirenk/android_device_htc_hima-common.git lineage-15.0
#git cherry-pick 874eb1f7fc8fcc58c0b4903ed9e07871089bb2ad

cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "Continue with rom build process (this segment can take an hour) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

echo "running brunch himaul..."
#lunch lineage_himaul-userdebug
#m -j brillo_update_payload
#m -j otatools
brunch himaul
