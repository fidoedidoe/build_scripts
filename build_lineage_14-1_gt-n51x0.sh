#!/bin/bash  

###
### USAGE: 
### ./build_lineage_14-1_GT-N51X0.sh <device>
### where device can be one of: N5100;N5110;N5120
### ie: ./build_lineage_14-1_GT-N51X0.sh N5110
###
### NOTE:
### you may need to modify the variables below to better suit your personal build environment 
###

WORK_DIRECTORY="$HOME/android/gt-n51x0-los-14.1"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
REPO_SYNC_THREADS=$(nproc --all)
LOS_REVISION="cm-14.1"
GITHUB_REPO="fidoedidoe"
MANIFEST_BRANCH="cm-14.1"
REPO_INIT_FLAGS="--depth=1 --no-clone-bundle"
REPO_SYNC_FLAGS="--quiet --force-sync --no-tags --no-clone-bundle"
CLONE_FLAGS="--depth 1"
SLEEP_DURATION="1"

echo "###"
echo "### Start of build script" 

if [[ ! -z "$1" ]]; then
  DEVICE_NAME="${1^^}"
  if [[ "$DEVICE_NAME" =~ ^(N5100|N5110|N5120)$ ]]; then
     echo "###"
  else
     echo "###"
     echo "### The passed parameter $DEVICE_NAME is not supported"
     echo "###"
     exit
  fi
else
  DEVICE_NAME="N5110"
  echo "###"
  echo "### No passed parameter $DEVICE_NAME assummed"
  echo "###"
fi

VANITY_DEVICE_TAG="Samsung Galaxy Note 8.0 (GT-$DEVICE_NAME)"
DEVICE_NAME="${DEVICE_NAME,,}"

echo "### Building for: $VANITY_DEVICE_TAG" 
echo "###"

PROMPT=""
read -r -p "### (1/6) Which build type? (1) Full LineageOS Rom build, (2) Only TWRP Recovery build. <1/2>? (automatically continues unprompted after 5 seconds): " -t 5 -e -i 1 PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="1"
fi
if [[ $PROMPT = "2" ]]; then
  BUILD_WITH_TWRP="true"
  echo "### Preparing for TWRP Recovery Build..."
else
  BUILD_WITH_TWRP="false"
  echo "### Preparing for Full LineageOS ROM build..."
fi

PROMPT=""
read -r -p "### (2/6) Initialise/Re-base LOS Repo's <Y/n>? (automatically continues unprompted after 5 seconds): " -t 5 -e -i Y PROMPT
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
  echo "### initialising LOS repo/manifests for first time..."
  repo init -u https://github.com/LineageOS/android.git -b $LOS_REVISION $REPO_INIT_FLAGS
else
  echo "### LOS repo/manifests exists..."
  echo "### Reverting all local LOS modifications..."
  repo forall -vc "git reset --hard ; git clean -fdx" --quiet
  echo "### Revert complete"
fi

PROMPT=""
read -r -p "### (3/6) Initialise local_manifest and perform repo sync (initial repo sync sync will take an age) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

if [ ! -d "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY" ]; then
  echo "### create 'local_manifest' and re-run repo sync..."           
  mkdir -p "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY"
  git clone $CLONE_FLAGS https://github.com/$GITHUB_REPO/android_.repo_local_manifests_gt-n51x0 -b $MANIFEST_BRANCH .repo/local_manifests
else
  echo "### $LOCAL_MANIFESTS_DIRECTORY already exists, skipping git clone"
fi

echo "### sync repo with $REPO_SYNC_THREADS threads..."
repo sync --jobs="$REPO_SYNC_THREADS" $REPO_SYNC_FLAGS


PROMPT=""
read -r -p "### (4/6) Prepare device specific code for: $VANITY_DEVICE_TAG <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

echo "### set environment var to stop issues with prebuilts/misc/.../flex"
export LC_ALL=C

echo "### set TWRP build directive and enable CONFIG_KERNEL_LZMA as necessary"
export WITH_TWRP=$BUILD_WITH_TWRP

echo "### preparing device specific code..."
source build/envsetup.sh
breakfast $DEVICE_NAME

echo "### running croot..."
croot

echo "### clearing old build output (if any exists)"           
mka clobber

cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "### (5/6) Apply patche(s) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

cd "$WORK_DIRECTORY"/frameworks/base || exit
echo "### applying patch device/samsung/n5100/patch/note-8-nougat-mtp-crash.patch"
patch -p 1 < ../../device/samsung/n5100/patch/note-8-nougat-mtp-crash.patch
sleep $SLEEP_DURATION

cd "$WORK_DIRECTORY"/external/wpa_supplicant_8/wpa_supplicant || exit
echo "### applying $LOCAL_MANIFESTS_DIRECTORY/0001_external_wpa-supplicant-8_wpa-supplicant_wpa-supplicant-template.patch"
patch -p 1 < ../../../$LOCAL_MANIFESTS_DIRECTORY/0001_external_wpa-supplicant-8_wpa-supplicant_wpa-supplicant-template.patch
sleep $SLEEP_DURATION

cd "$WORK_DIRECTORY" || exit


PROMPT=""
read -r -p "### (6/6) Start $VANITY_DEVICE_TAG build process (this step can take some time depending on CC_CACHE) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ $PROMPT =~ ^[Yy]$ ]]; then
   PROMPT=""
   if [[ $BUILD_WITH_TWRP = "true" ]]; then
       echo "### running 'mka recoveryimage..."
       mka recoveryimage
   else
       echo "### running 'brunch $DEVICE_NAME..."
       #mka bacon -j$REPO_SYNC_THREADS
       brunch $DEVICE_NAME
   fi
else
   echo "### Response: '$PROMPT', exiting!"
   exit 1
fi

echo "### End of Build Script for $VANITY_DEVICE_TAG! ###"
