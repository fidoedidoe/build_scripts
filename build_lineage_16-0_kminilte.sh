#!/bin/bash  

WORK_DIRECTORY="$HOME/android/kminilte-16.0"
SAMPLE_REPO_DIRECTORY='frameworks'
LOCAL_MANIFESTS_DIRECTORY='.repo/local_manifests'
REPO_SYNC_THREADS=6
CLEAN=0
LOS_REVISION="lineage-16.0"
SPOOK_CITY_REVISION="P"

PROMPT=""
read -r -p "### (1/7) Start Repo Sync and Build process, first 'repo init' will take hours <Y/n>? (automatically continues unpromted after 5 seconds): " -t 5 -e -i Y PROMPT
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
  repo forall -vc "git reset --hard ; git clean -fdx" --quiet
  CLEAN=1
fi

PROMPT=""
read -r -p "### (2/7) Continue and sync repo <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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
read -r -p "### (3/7) Initialise/Reinitialse additional local manifests <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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
  git clone -b $SPOOK_CITY_REVISION https://github.com/Spookcity/android_device_samsung_smdk3470-common device/samsung/smdk3470-common
else
  echo "### directory $WORK_DIRECTORY/device/samsung/smdk3470-common exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/device/samsung/smdk3470-common || exit
  git reset --hard origin/$SPOOK_CITY_REVISION
  git clean -fd
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/device/samsung/kminilte" ]; then
  echo '### local manifest directory device/samsung/kminilte doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION https://github.com/Spookcity/android_device_samsung_kminilte device/samsung/kminilte
else
  echo "### directory $WORK_DIRECTORY/device/samsung/kminilte exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/device/samsung/kminilte || exit
  git reset --hard origin/$SPOOK_CITY_REVISION
  git clean -fd
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/kernel/samsung/kminilte" ]; then
  echo '### local manifest directory kernel/samsung/kminilte doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION https://github.com/Spookcity/android_kernel_samsung_kminilte kernel/samsung/kminilte
else
  echo "### directory $WORK_DIRECTORY/kernel/samsung/kminilte exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/kernel/samsung/kminilte || exit
  git reset --hard origin/$SPOOK_CITY_REVISION
  git clean -fd
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/vendor/samsung/kminilte" ]; then
  echo '### local manifest vendor/samsung/kminilte directory doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION https://github.com/Spookcity/android_vendor_samsung_kminilte vendor/samsung/kminilte
else
  echo "### directory $WORK_DIRECTORY/vendor/samsung/kminilte exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/vendor/samsung/kminilte || exit
  git reset --hard origin/$SPOOK_CITY_REVISION
  git clean -fd
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/hardware/samsung" ]; then
  echo '### local manifest directory hardware/samsung doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION https://github.com/Spookcity/android_hardware_samsung hardware/samsung
else
  echo "### directory $WORK_DIRECTORY/hardware/samsung exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/hardware/samsung || exit
  git reset --hard origin/$SPOOK_CITY_REVISION
  git clean -fd
  cd "$WORK_DIRECTORY" || exit
fi

if [ ! -d "$WORK_DIRECTORY/hardware/samsung_slsi/exynos3470" ]; then
  echo '### local manifest directory hardware/samsung_slsi/exynos3470 doesnt exist, clone it...'
  git clone -b $SPOOK_CITY_REVISION https://github.com/Spookcity/android_hardware_samsung_slsi_exynos3470 hardware/samsung_slsi/exynos3470
else
  echo "### directory $WORK_DIRECTORY/hardware/samsung_slsi/exynos3470 exists...runnning: git reset --hard"
  cd "$WORK_DIRECTORY"/hardware/samsung_slsi/exynos3470 || exit
  git reset --hard origin/$SPOOK_CITY_REVISION
  git clean -fd
  cd "$WORK_DIRECTORY" || exit
fi

PROMPT=""
read -r -p "### (4/7) Continue and apply device specific patch <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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
read -r -p "### (5/7) Continue and prepare device specific code <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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
read -r -p "### (6/7) Apply kernel optimisations (cherry-pick from SpookCity N_custom kernel optimsations), inspiration and initial patch credited to Panzerknakker)  <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

cd "$WORK_DIRECTORY"/kernel/samsung/kminilte || exit

echo "### apply cpufreq patch provided by PanzerKnakker this initialses the file to prevent merge conflicts when cherry picking, see: https://forum.xda-developers.com/showpost.php?p=79571283&postcount=325"
git apply ~/android/build_scripts/build_lineage_16-0_kminilte_0001-prepare-cpufreq.patch
git add drivers/cpufreq/exynos3470-cpufreq.c
git commit -m "modified to match cherry-pick a20c1790de4d5152d986ca52563f20769c14ab69 start position as origin/P doesn't match origin/N_custom for cpufreq.c on lines 552 and 553"

echo "### cherry-pick 001 - 1.6ghz OC and initial voltage stuffs"
git cherry-pick a20c1790de4d5152d986ca52563f20769c14ab69

echo "### cherry-pick 002 - voltage table access"
git cherry-pick 81d88aae7262d17a4538440d783dbc3ed80ffcc1

echo "### cherry-pick 003 - GPU OC to 533mhz"
git cherry-pick 505dd3782eb63b56113dd2c1095e981c90c7d9fc

echo "### cherry-pick 004 - GPU OC to 600mhz"
git cherry-pick 548b71b9417b3e9628b71e2e2f6dc93494a4d886

echo "### cherry-pick 005 - CPU voltage control"
git cherry-pick ac265ac6e7ea1905abef0b8bfdd1c6996004b08f

echo "### cherry-pick 006 - lib/int_sqrt.c optimise square root algorithm"
git cherry-pick dd91ace39766f6f3e92bd4b37c88d4f18d3a1435

echo "### cherry-pick 007 - af_unix speedup /proc/net/unix"
git cherry-pick bd7b120e643d9ff129c430fc262a6688d6849e6b

echo "### cherry-pick 008 - lower arm_max-volt"
git cherry-pick 1ccd52491ed93f63ab8082bdfae193ac41633df9

echo "### cherry-pick 009 - GPU Optimsations Flags"
git cherry-pick d774f273b1aa3d54943d6b814e9b4331eacf2ec0

echo "### cherry-pick 010 - audit: Make logging opt-in via console_loglevel"
git cherry-pick 429e4d526dc0a4661e376dfe75119aac7d91da97 

echo "### cherry-pick 011 - audit:No logging"
git cherry-pick 1a9c354552d6bd7f37444ddd61adc46e2f640c17 

cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "### (7/7) Continue with ROM build process (this step can take more than an hour depending on CC_CACHE) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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
