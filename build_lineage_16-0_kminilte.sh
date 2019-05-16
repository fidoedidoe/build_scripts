#!/bin/bash  

WORK_DIRECTORY="$HOME/android/kminilte-16.0"
SAMPLE_REPO_DIRECTORY='frameworks'
LOCAL_MANIFESTS_DIRECTORY='.repo/local_manifests'
REPO_SYNC_THREADS=8
CLEAN=0
LOS_REVISION="lineage-16.0"
SPOOK_CITY_REVISION="P"

PROMPT=""
read -r -p "### (1/6) Start Repo Sync and Build process, first 'repo init' will take hours <Y/n>? (automatically continues unpromted after 5 seconds): " -t 5 -e -i Y PROMPT
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
	
if [ ! -d "$SAMPLE_REPO_DIRECTORY" ]; then
  echo "### initialising repo for first time..."
  mkdir -p "$WORK_DIRECTORY"/"$LOCAL_MANIFESTS_DIRECTORY"
  rm -rf "$WORK_DIRECTORY"/"$LOCAL_MANIFESTS_DIRECTORY"/*
  repo init -u https://github.com/LineageOS/android.git -b $LOS_REVISION
else
  echo "### repo exists, reverting all local modifications..."
  repo forall -vc "git reset --hard" --quiet
  CLEAN=1
fi

PROMPT=""
read -r -p "### (2/6) Continue and sync repo <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

echo "### sync repo..."
repo sync -c --quiet --jobs="$REPO_SYNC_THREADS"

if [ "$CLEAN" -eq "0" ]; then
  echo "### create local_manifests and rerunning repo sync..."           
  ##mkdir -p "$WORK_DIRECTORY"/"$LOCAL_MANIFESTS_DIRECTORY"
  git clone https://github.com/Spookcity/android_.repo_local_manifests -b $SPOOK_CITY_REVISION .repo/local_manifests
  repo sync -c --quiet --jobs="$REPO_SYNC_THREADS"
fi

PROMPT=""
read -r -p "### (3/6) Initialise/Reinitialse additional local manifests <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

echo "### get/reset local manifest..."
if [ ! -d "$WORK_DIRECTORY/device/samsung/smdk3470-common" ]; then
  echo '### local manifest directory device/samsung/smdk-common doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION http://github.com/Spookcity/android_device_samsung_smdk3470-common device/samsung/smdk3470-common
else
  echo "### directory $WORK_DIRECTORY/device/samsung/smdk3470-common exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/device/samsung/smdk3470-common || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/device/samsung/kminilte" ]; then
  echo '### local manifest directory device/samsung/kminilte doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION http://github.com/Spookcity/android_device_samsung_kminilte device/samsung/kminilte
else
  echo "### directory $WORK_DIRECTORY/device/samsung/kminilte exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/device/samsung/kminilte || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/kernel/samsung/kminilte" ]; then
  echo '### local manifest directory kernel/samsung/kminilte doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION http://github.com/Spookcity/android_kernel_samsung_kminilte kernel/samsung/kminilte
else
  echo "### directory $WORK_DIRECTORY/kernel/samsung/kminilte exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/kernel/samsung/kminilte || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/vendor/samsung/kminilte" ]; then
  echo '### local manifest vendor/samsung/kminilte directory doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION http://github.com/Spookcity/android_vendor_samsung_kminilte vendor/samsung/kminilte
else
  echo "### directory $WORK_DIRECTORY/vendor/samsung/kminilte exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/vendor/samsung/kminilte || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/hardware/samsung" ]; then
  echo '### local manifest directory hardware/samsung doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION http://github.com/Spookcity/android_hardware_samsung hardware/samsung
else
  echo "### directory $WORK_DIRECTORY/hardware/samsung exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/hardware/samsung || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/hardware/samsung_slsi/exynos3470" ]; then
  echo '### local manifest directory hardware/samsung_slsi/exynos3470 doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION http://github.com/Spookcity/android_hardware_samsung_slsi_exynos3470 hardware/samsung_slsi/exynos3470
else
  echo "### directory $WORK_DIRECTORY/hardware/samsung_slsi/exynos3470 exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/hardware/samsung_slsi/exynos3470 || exit
  git reset --hard
  cd "$WORK_DIRECTORY" || exit
fi

PROMPT=""
read -r -p "### (4/6) Continue and apply device specific patch <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

#Patch script
cd "$WORK_DIRECTORY"/device/samsung/smdk3470-common/patch || exit
./apply.sh
cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "### (5/6) Continue and prepare device specific code <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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
lunch lineage_kminilte-userdebug

echo "### running croot..."
croot

echo "### CLEAN variable is: $CLEAN" 
if [ "$CLEAN" -eq "1" ]; then
  echo "### clearing old build output"           
  mka clobber
fi

cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "### (6/6) Continue with ROM build process (this step can take more than an hour depending on CC_CACHE) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

echo "### running 'mka bacon'..."
mka bacon

echo "### End of Build Script ###"
