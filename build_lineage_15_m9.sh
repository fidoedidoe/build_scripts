#!/bin/bash  

INSERT_TEXT='  <?xml version="1.0" encoding="UTF-8"?>\n    <manifest>\n      <project name="LineageOS/android_device_htc_himaul" path="device/htc/himaul" remote="github" />\n      <project name="LineageOS/android_device_htc_himawl" path="device/htc/himawl" remote="github" />\n      <project name="LineageOS/android_device_htc_hima-common" path="device/htc/hima-common" remote="github" />\n      <project name="LineageOS/android_kernel_htc_msm8994" path="kernel/htc/msm8994" remote="github" />\n      <project name="LineageOS/android_device_qcom_common" path="device/qcom/common" remote="github" />\n      <project name="LineageOS/android_packages_resources_devicesettings" path="packages/resources/devicesettings" remote="github" />\n      <project name="TheMuppets/proprietary_vendor_htc" path="vendor/htc" remote="github" />\n    </manifest>\n'

SAMPLE_REPO_DIRECTORY='frameworks'
WORK_DIRECTORY="$HOME/android/rom"
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
  repo init -u https://github.com/LineageOS/android.git -b $LOS_REVISION
else
  echo "repo exists, reverting all local modifications..."
  mka clobber
  repo forall -vc "git reset --hard" --quiet
  #CLEAN=1
fi

PROMPT=""
read -r -p "Continue with build process <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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

PROMPT=""
read -r -p "Continue with build process <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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

echo "run repopick ..."
#repopick 194359 195049 194361 195889 195899 195943 195944
#repopick 196446
##repopick 190165 190166 187514 186687
#repopick 190165 190166 187514

# From: https://review.lineageos.org/#/q/project:LineageOS/android_device_htc_hima-common
repopick 194359 195049 195889 195899 194361 196446 195944 195943
# From: https://review.lineageos.org/#/q/project:LineageOS/android_hardware_qcom_audio
repopick 187514 190166 190165


echo "git fetch flyhalf205 and cherry pick..."
cd "$WORK_DIRECTORY"/vendor/htc/ || exit
git fetch https://github.com/Flyhalf205/proprietary_vendor_htc.git lineage-15.0
#git cherry-pick 3c1d2adb68b975d297929e0db56735a29229f9c4
#git cherry-pick 63cbead7fa978d101ee5bfd869a1bab6b97525b9
#git cherry-pick 88f5ddccbde9438e645075847305d2d01de448f7
git cherry-pick a01cd415790266b49ba3bc6c87e4d499eabd8632
git cherry-pick dbce6a0c8364fefa447aa98c22e6da08c94c55b3
git cherry-pick c6c1494596da5e3ff95b3a708b79c7ed70a12a82

echo "git fetch Mirnek and cherry pick..."
cd "$WORK_DIRECTORY"/device/htc/hima-common/
git fetch https://github.com/Mirenk/android_device_htc_hima-common.git lineage-15.0
git cherry-pick 874eb1f7fc8fcc58c0b4903ed9e07871089bb2ad

cd "$WORK_DIRECTORY" || exit

#if [ "$CLEAN" -eq "1" ]; then
#  echo "mka clean/clobber needed..."     	
#  #mka clean
#  mka clobber
#fi
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
lunch lineage_himaul-userdebug
m -j brillo_update_payload
m -j otatools
brunch himaul
