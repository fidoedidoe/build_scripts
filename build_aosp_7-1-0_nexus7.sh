#!/bin/bash  

###
### USAGE: 
### ./build_aosp_7-1-0_nexus7.sh <device>
### where device can be one of: tilapia;grouper
### ie: ./build_lineage_14-1_GT-N51X0.sh tilapia
###
### NOTE:
### you may need to modify the variables below to better suit your personal build environment 
###


#GITHUB_USER="AndDiSa"
GITHUB_USER="fidoedidoe"
GITHUB_BRANCH_PREFIX="ads"
#GITHUB_BRANCH_PREFIX="fidoe"
GITHUB_BRANCH="$GITHUB_BRANCH_PREFIX-7.1.0"
WORK_DIRECTORY="$HOME/android/aosp_7-1-0_nexus7"
#WORK_DIRECTORY="$WORK_DIRECTORY-$GITHUB_BRANCH_PREFIX"
REPO_DIRECTORY='.repo'
REPO_SYNC_THREADS=$(nproc --all)
REPO_INIT_FLAGS="--depth=1 --no-clone-bundle"
#REPO_INIT_FLAGS="--no-clone-bundle"
REPO_SYNC_FLAGS="--quiet --force-sync --no-tags --no-clone-bundle"
#REPO_SYNC_FLAGS="--quiet --force-sync --force-broken --no-tags --no-clone-bundle"
SLEEP_DURATION="1"
APPLY_PATCHES="True"

echo "###"
echo "### Start of build script for: $AOSP_DEVICE" 
echo "###"

if [[ ! -z "$1" ]]; then
  DEVICE_NAME="${1,,}"
  if [[ "$DEVICE_NAME" =~ ^(tilapia|grouper)$ ]]; then
     echo "###"
  else
     echo "###"
     echo "### The passed parameter $DEVICE_NAME is not supported"
     echo "###"
     exit
  fi
else
  DEVICE_NAME="tilapia"
  echo "###"
  echo "### No passed parameter $DEVICE_NAME assummed"
  echo "###"
fi


VANITY_DEVICE_TAG="Nexus7 2012 ($DEVICE_NAME)"
AOSP_DEVICE="aosp_$DEVICE_NAME-userdebug"

echo "### Building for: $VANITY_DEVICE_TAG"
echo "###"


PROMPT=""
read -r -p "### (1/5) Install Git repo and manifest ('repo init') for $AOSP_DEVICE <Y/n>? (automatically continues unprompted after 5 seconds): " -t 5 -e -i Y PROMPT
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
  echo "### initialising git repo for first time..."
  repo init $REPO_INIT_FLAGS -u https://github.com/$GITHUB_USER/platform_manifest-Grouper-AOSP.git -b $GITHUB_BRANCH
else
  echo "### git Repo exists..."
  echo "### step 1/1: reverting all local  modifications..."
  repo forall -vc "git reset --hard ; git clean -fdx" --quiet
  echo "### step 1 - 1: complete"
fi

PROMPT=""
read -r -p "### (2/5) Sync project repo's (first run can take a long time depending on internet bandwidth)<Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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

if [[ $APPLY_PATCHES =~ "True" ]]; then
  PROMPT=""
  read -r -p "### (3/5) Apply device specific patch <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
  echo
  if [ -z "$PROMPT" ]; then
    PROMPT="Y"
  fi
  if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
    echo "### Response: '$PROMPT', exiting!"
    exit 1
  fi

  #changes pmf=1 value to pmf=0, which impacts wifi connectivity on some routers (disconnect/reconnect until failure) 
  cd "$WORK_DIRECTORY"/external/wpa_supplicant_8/wpa_supplicant || exit
  echo "### applying patch .repo/manifests/external_wpa-supplicant-template.patch"
  patch -p 1 < "$WORK_DIRECTORY"/"$REPO_DIRECTORY"/manifests/external_wpa-supplicant-template.patch
  sleep $SLEEP_DURATION

fi

cd "$WORK_DIRECTORY" || exit


PROMPT=""
read -r -p "### (4/5) Prepare device specific code <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

echo "### prepare device specific code for $AOSP_DEVICE..."
source build/envsetup.sh
lunch $AOSP_DEVICE

echo "### running croot..."
croot

echo "### set environment var to stop issues with prebuilts/misc/.../flex"
export LC_ALL=C

echo "### remove previous build output"
rm -rf out/*

cd "$WORK_DIRECTORY" || exit


PROMPT=""
read -r -p "### (5/5) Build ROM  (this step can a long time, ccache hit success will significantly reduce this) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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
