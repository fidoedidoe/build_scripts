#!/bin/bash  

INSERT_TEXT_1='    <!-- Is the battery LED intrusive? Used to decide if there should be a disable option -->\n    <bool name="config_intrusiveBatteryLed">true</bool>\n\n    <!-- Hardware keys present on the device, stored as a bit field.\n          This integer should equal the sum of the corresponding value for each\n          of the following keys present:\n           1 - Home\n           2 - Back\n           4 - Menu\n           8 - Assistant (search)\n          16 - App switch\n          32 - Camera\n          64 - Volume rocker\n         For example, a device with Home, Back and Menu keys would set this config to 7. -->\n    <integer name="config_deviceHardwareKeys">83</integer>\n\n    <!-- Hardware keys present on the device with the ability to wake, stored as a bit field.\n          This integer should equal the sum of the corresponding value for each\n          of the following keys present:\n           1 - Home\n           2 - Back\n           4 - Menu\n           8 - Assistant (search)\n          16 - App switch\n          32 - Camera\n          64 - Volume rocker\n         For example, a device with Home, Back and Menu keys would set this config to 7. -->\n    <integer name="config_deviceHardwareWakeKeys">65</integer>\n\n    <!-- Control the behavior when the user long presses the app switch button.\n          0 - Nothing\n          1 - Menu key\n          2 - Recent apps view in SystemUI\n          3 - Launch assist intent\n          4 - Voice Search\n          5 - In-app Search\n         This needs to match the constants in\n          policy/src/com/android/internal/policy/impl/PhoneWindowManager.java -->\n    <integer name="config_longPressOnAppSwitchBehavior">1</integer>\n\n</resources>'
INSERT_TEXT_2='#define SEC_PRODUCT_FEATURE_RIL_CALL_DUALMODE_CDMAGSM 1\n'
SAMPLE_REPO_DIRECTORY='frameworks'
WORK_DIRECTORY="$HOME/android/slimrom7"
REPO_SYNC_THREADS=16
CLEAN=0
SLIM_REVISION="ng7.1"
LOS_REVISION="cm-14.1"

PROMPT=""
read -r -p "1/7. Initialise/Reinitialise Repo, first 'repo init' will take hours <Y/n>? (automatically continues unpromted after 5 seconds): " -t 5 -e -i Y PROMPT
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
  repo init -u https://github.com/SlimRoms/platform_manifest.git -b $SLIM_REVISION
else
  echo "repo exists, reverting all local modifications..."
  repo forall -vc "git reset --hard" --quiet
  CLEAN=1
fi

echo "sync repo..."
repo sync --quiet --jobs="$REPO_SYNC_THREADS"

PROMPT=""
read -r -p "2/7. Initialise/Reinitialse additional local manifests <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

echo "get/reset local manifest..." 
if [ ! -d "$WORK_DIRECTORY/device/samsung/kminilte" ]; then
  echo 'local manifest directory device/samsung/kminilte doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/cm-3470/android_device_samsung_kminilte device/samsung/kminilte
else
  echo "directory $WORK_DIRECTORY/device/samsung/kminilte exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/device/samsung/kminilte || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/vendor/samsung/kminilte" ]; then
  echo 'local manifest vendor/samsung/kminilte directory doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/cm-3470/android_vendor_samsung_kminilte vendor/samsung/kminilte
else
  echo "directory $WORK_DIRECTORY/vendor/samsung/kminilte exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/vendor/samsung/kminilte || exit 
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/kernel/samsung/kminilte" ]; then
  echo 'local manifest directory kernel/samsung/kminilte doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/cm-3470/android_kernel_samsung_kminilte kernel/samsung/kminilte
else
  echo "directory $WORK_DIRECTORY/kernel/samsung/kminilte exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/kernel/samsung/kminilte || exit 
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

#echo "unconditionally removing folder device/samsung/smdk3470-common..."
#rm -rf "$WORK_DIRECTORY"/device/samsung/smdk3470-common

if [ ! -d "$WORK_DIRECTORY/device/samsung/smdk3470-common" ]; then
  echo 'local manifest directory device/samsung/smdk-common doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/cm-3470/android_device_samsung_smdk3470-common device/samsung/smdk3470-common
else
  echo "directory $WORK_DIRECTORY/device/samsung/smdk3470-common exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/device/samsung/smdk3470-common || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/hardware/samsung_slsi/exynos3470" ]; then
  echo 'local manifest directory hardware/samsung_slsi/exynos3470 doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/cm-3470/android_hardware_samsung_slsi_exynos3470 hardware/samsung_slsi/exynos3470
else
  echo "directory $WORK_DIRECTORY/hardware/samsung_slsi/exynos3470 exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/hardware/samsung_slsi/exynos3470 || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/packages/apps/SamsungServiceMode" ]; then
  echo 'local manifest directory packages/apps/SamsungServiceMode doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/LineageOS/android_packages_apps_SamsungServiceMode packages/apps/SamsungServiceMode
else
  echo "directory $WORK_DIRECTORY/packages/apps/SamsungServiceMode exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/packages/apps/SamsungServiceMode || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/packages/apps/FlipFlap" ]; then
  echo 'local manifest directory packages/apps/FlipFlap doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/LineageOS/android_packages_apps_FlipFlap packages/apps/FlipFlap
else
  echo "directory $WORK_DIRECTORY/packages/apps/FlipFlap exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/packages/apps/FlipFlap || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/packages/resources/devicesettings" ]; then
  echo 'local manifest directory packages/resources/devicesettings doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/LineageOS/android_packages_resources_devicesettings packages/resources/devicesettings
else
  echo "directory $WORK_DIRECTORY/packages/resources/devicesettings exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/packages/resources/devicesettings || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/hardware/samsung" ]; then
  echo 'local manifest directory hardware/samsung doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/LineageOS/android_hardware_samsung hardware/samsung
else
  echo "directory $WORK_DIRECTORY/hardware/samsung exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/hardware/samsung || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/external/stlport" ]; then
  echo 'local manifest directory externel/stlport doesnt exist, clone it...' 
  git clone -b $LOS_REVISION http://github.com/LineageOS/android_external_stlport external/stlport
else
  echo "directory $WORK_DIRECTORY/external/stlport exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/external/stlport || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

PROMPT=""
read -r -p "3/7. Resync primary repo and additional local manifests <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

echo "Sync Repo..."
repo sync --quiet --jobs="$REPO_SYNC_THREADS"

PROMPT=""
read -r -p "4/7. Modify source for build<Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

echo "Remove references to OmniRom recovery..."
sed -i 's/^ifeq ($(TARGET_BUILD_VARIANT),userdebug)/#ifeq ($(TARGET_BUILD_VARIANT),userdebug)/g' "$WORK_DIRECTORY"/device/samsung/kminilte/BoardConfig.mk 
sed -i 's/^RECOVERY_VARIANT := twrp/#RECOVERY_VARIANT := twrp/g' "$WORK_DIRECTORY"/device/samsung/kminilte/BoardConfig.mk 
sed -i 's/^endif/#endif/g' "$WORK_DIRECTORY"/device/samsung/kminilte/BoardConfig.mk 

echo "remove config_uriBlruEnabled references, spoils the build..."
sed -i 's/<bool name="config_uiBlurEnabled">true<\/bool>/<!--bool name="config_uiBlurEnabled">true<\/bool-->/g' "$WORK_DIRECTORY"/device/samsung/kminilte/overlay/frameworks/base/core/res/res/values/config.xml

echo "alter local manifest files for slimrom 7 build compatability..."
cd "$WORK_DIRECTORY"/device/samsung/kminilte || exit
sed -i 's/lineage/slim/g' lineage.mk && sed -i 's/cm/slim/g' lineage.mk && sed -i 's/full_kminilte/slim_kminilte/g' full_kminilte.mk && sed -i 's/lineage/slim/g' vendorsetup.sh && mv lineage.mk slim.mk
cd "$WORK_DIRECTORY" || exit

echo "insert text into file: frameworks/base/core/res/res/values/config.xml..."
eval "sed -i 's^</resources>^$INSERT_TEXT_1^g' $WORK_DIRECTORY/frameworks/base/core/res/res/values/config.xml"

echo 'delete file cm_arrays.xml...'
rm "$WORK_DIRECTORY"/device/samsung/kminilte/overlay/frameworks/base/core/res/res/values/cm_arrays.xml

echo "remove flipflap stuff from device/samsung/smdk3470-common/smdk3470-common.mk..."
## WARN - maybe change this to search replace (will break easily) 
sed -i -e '91,92d' "$WORK_DIRECTORY"/device/samsung/smdk3470-common/smdk3470-common.mk

PROMPT=""
read -r -p "5/7. Apply Patches <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

#due to issues with patch apply the two following patxhes manually, 
#before running patch script ./apply.sh

#Patch #1 (one stpe fails so manually edit ril.h)
cd "$WORK_DIRECTORY"/hardware/ril/
mv "$WORK_DIRECTORY"/device/samsung/smdk3470-common/patch/hardware_ril/0001-ril-adjust-to-G800F-MM-ril-G800FXXU1CPK5.patch .
patch -p1 < 0001-ril-adjust-to-G800F-MM-ril-G800FXXU1CPK5.patch
echo "manually reapplying failed Hunk #1..."
eval "sed -i '34i$INSERT_TEXT_2' $WORK_DIRECTORY/hardware/ril/include/telephony/ril.h"
cd "$WORK_DIRECTORY" || exit

#Patch #2
cd "$WORK_DIRECTORY"/hardware/samsung/
mv "$WORK_DIRECTORY"/device/samsung/smdk3470-common/patch/hardware_samsung_ril/0001-add-support-for-ss222.patch .
patch -p1 < 0001-add-support-for-ss222.patch
cd "$WORK_DIRECTORY" || exit

#Patch script
cd "$WORK_DIRECTORY"/device/samsung/smdk3470-common/patch || exit
./apply.sh
cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "6/7. Initialise environment for Build <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

echo "prepare device specific code..."
source build/envsetup.sh 
lunch slim_kminilte-userdebug

echo "running croot..."
croot
if [ "$CLEAN" -eq "1" ]; then
  echo "mka clean/clobber needed..."     	
  #mka clean
  mka clobber
fi


PROMPT=""
read -r -p "7/7. Build rom (this segment can take hours) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "Response: '$PROMPT', exiting!"
  exit 1
fi

echo "running mka bacon..."
mka bacon
