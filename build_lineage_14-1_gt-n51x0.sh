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

#############
# Variable(s)
#############

LOS_PREFIX="cm"
LOS_VERSION="14.1"
LINARO_VERSION="linaro-7.4.1-cortex-a9-neon"
WORK_DIRECTORY="$HOME/android/gt-n51x0-los-$LOS_VERSION"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
REPO_SYNC_THREADS=$(nproc --all)
LOS_REVISION="$LOS_PREFIX-$LOS_VERSION"
GITHUB_REPO="fidoedidoe"
MANIFEST_BRANCH="$LOS_PREFIX-$LOS_VERSION"
REPO_INIT_FLAGS="--depth=1 --no-clone-bundle"
REPO_SYNC_FLAGS="--quiet --force-sync --no-tags --no-clone-bundle"
CLONE_FLAGS="--depth 1"
SLEEP_DURATION="1"
KERNEL_CROSS_COMPILE=""$WORK_DIRECTORY"/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-linux-androideabi-"
NOW=$(date +"%Y%m%d")

#############
# Function(s)
#############

unsupported_response () {
  echo "### Response: '$1' entered, only (Y/y) proceeds....exiting script!"
  exit 1
}

#####################
# Main body of script
#####################
echo "###"
echo "### Start of build script" 

if [[ -n "$1" ]]; then
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
echo "### (1/6) Which build type (ROM, Recovery, Kernel? "
echo "###       #1. Full LineageOS $LOS_VERSION Build"
echo "###       #2. TWRP Recovery Only"
echo "###       #3. LineageOS Kernel Only"
read -r -p "### Enter build choice <1/2/3>? (automatically continues unprompted after 5 seconds): " -t 5 -e -i 1 PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="1"
fi

if [[ "$PROMPT" =~ ^(1|2|3)$ ]]; then
  case "$PROMPT" in
   "1") echo "### Selected: Full LineageOS ROM build..."
        BUILD_TYPE="full";;
   "2") echo "### Selected: TWRP Recovery Build..."
        BUILD_TYPE="recovery";;
   "3") echo "### Selected LineageOS Kernel Build..."
        BUILD_TYPE="kernel";;    
  esac	  
else
  unsupported_response "$PROMPT"
fi

PROMPT=""
read -r -p "### (2/6) Initialise/Re-base LOS Repo's <Y/n>? (automatically continues unprompted after 5 seconds): " -t 5 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  unsupported_response "$PROMPT"
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
  unsupported_response "$PROMPT"
fi

if [ ! -d "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY" ]; then
  echo "### create 'local_manifest' and re-run repo sync..."           
  mkdir -p "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY"
  git clone $CLONE_FLAGS https://github.com/$GITHUB_REPO/android_.repo_local_manifests_gt-n51x0 -b "$MANIFEST_BRANCH" .repo/local_manifests
else
  echo "### $LOCAL_MANIFESTS_DIRECTORY already exists, skipping git clone"
fi

echo "### sync repo with $REPO_SYNC_THREADS threads..."
repo sync --jobs=$REPO_SYNC_THREADS $REPO_SYNC_FLAGS


PROMPT=""
read -r -p "### (4/6) Prepare device specific code for: $VANITY_DEVICE_TAG <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  unsupported_response "$PROMPT"
fi

#The following is unecessary for kernel build
if [[ ! $BUILD_TYPE = "kernel" ]]; then

   #In order to build a full rom with the kernwl cm-14.1-custom branch
   #the toolchain specific optimisations need to be revoked (from Makefile). Easiest 
   #method to do this was to revert to an earlier version of the impacted file(s)
   #from commit "O3 plus lots of optimization flags"    

   #echo "### we're building "$BUILD_TYPE", revert build flag optimisations in Makefile"
   cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412 || exit

   #we only got cm-14.1-custom earlier. now get standard cm-14.1 branch 
   git fetch github cm-14.1

   git checkout github/cm-14.1 -- Makefile

   cd "$WORK_DIRECTORY" || exit

   echo "### set environment var to stop issues with prebuilts/misc/.../flex"
   export LC_ALL=C

   echo "### preparing device specific code..."
   source build/envsetup.sh
   breakfast lineage_$DEVICE_NAME-user

   echo "### running croot..."
   croot

   echo "### clearing old build output (if any exists)"           
   mka clobber
else
   echo "### Building kernel, nothing to do here!"           
fi

cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "### (5/6) Apply patche(s) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  unsupported_response "$PROMPT"
fi

cd "$WORK_DIRECTORY"/frameworks/base || exit
echo "### applying patch device/samsung/n5100/patch/note-8-nougat-mtp-crash.patch"
patch -p 1 < ../../device/samsung/n5100/patch/note-8-nougat-mtp-crash.patch
sleep $SLEEP_DURATION

cd "$WORK_DIRECTORY"/external/wpa_supplicant_8/wpa_supplicant || exit
echo "### applying $LOCAL_MANIFESTS_DIRECTORY/0001_external_wpa-supplicant-8_wpa-supplicant_wpa-supplicant-template.patch"
patch -p 1 < ../../../$LOCAL_MANIFESTS_DIRECTORY/0001_external_wpa-supplicant-8_wpa-supplicant_wpa-supplicant-template.patch
sleep $SLEEP_DURATION

case "$BUILD_TYPE" in
  "full") cd "$WORK_DIRECTORY" || exit
          echo "### applying $LOCAL_MANIFESTS_DIRECTORY/0002-custom-toolchain-optimisation.patch"
          patch -p 1 < $LOCAL_MANIFESTS_DIRECTORY/0002-custom-toolchain-optimisation.patch;;
  "kernel") 
          if [[ $DEVICE_NAME = "n5100" ]]; then
             cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3 || exit
             echo "### applying $LOCAL_MANIFESTS_DIRECTORY/0003-AnyKernel3-N5100-Device-Names.patch"
             patch -p 1 < ../../../../$LOCAL_MANIFESTS_DIRECTORY/0003-AnyKernel3-N5100-Device-Names.patch
             sleep $SLEEP_DURATION
          fi
          if [[ $DEVICE_NAME = "n5120" ]]; then
             cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3 || exit
             sleep $SLEEP_DURATION
             echo "### applying $LOCAL_MANIFESTS_DIRECTORY/0004-AnyKernel3-N5120-Device-Names.patch"
             patch -p 1 < ../../../../$LOCAL_MANIFESTS_DIRECTORY/0004-AnyKernel3-N5120-Device-Names.patch
             sleep $SLEEP_DURATION
          fi;;
esac

cd "$WORK_DIRECTORY" || exit


PROMPT=""
read -r -p "### (6/6) Start $VANITY_DEVICE_TAG build process (this step can take some time depending on CC_CACHE) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ $PROMPT =~ ^[Yy]$ ]]; then
   PROMPT=""
   case "$BUILD_TYPE" in
    "full")     echo "### Starting $BUILD_TYPE build, running 'brunch $DEVICE_NAME'..."
                brunch lineage_$DEVICE_NAME-user;;

    "recovery") echo "### Starting $BUILD_TYPE build, running 'mka recoveryimage'..."
                export WITH_TWRP="true"
                mka recoveryimage
                cd "$WORK_DIRECTORY"/out/target/product/n5110/ || exit 
                mv recovery.img twrp-"$DEVICE_NAME"-"$NOW".img
                echo "### TWRP flashable image name: twrp-$DEVICE_NAME-$NOW.img";;

    "kernel")   echo "### Starting $BUILD_TYPE build..."
                export CROSS_COMPILE="$KERNEL_CROSS_COMPILE"
		export ARCH=arm
		export SUBARCH=arm
                cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/ || exit
                mkdir -p "$WORK_DIRECTORY"/out
                echo "CROSS_COMPILE: $CROSS_COMPILE"
                echo "defconfig: lineageos_"$DEVICE_NAME"_defconfig"
	        make O="$WORK_DIRECTORY"/out clean
                make O="$WORK_DIRECTORY"/out mrproper
                make O="$WORK_DIRECTORY"/out lineageos_"$DEVICE_NAME"_defconfig
                make O="$WORK_DIRECTORY"/out -j"$REPO_SYNC_THREADS"
                cp "$WORK_DIRECTORY"/out/arch/arm/boot/zImage "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3
                echo "### building flashable anykernel3 zip file...."
                cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3 || exit
                zip -r9 kernel.zip * -x .git README.md *placeholder kernel.zip
                rm zImage
                mv kernel.zip "$WORK_DIRECTORY"/out/arch/arm/boot/
                cd "$WORK_DIRECTORY"/out/arch/arm/boot/ || exit
                mv kernel.zip GT-"$DEVICE_NAME"-kernel-los"$LOS_VERSION"-"$LINARO_VERSION"."$NOW".zip
                echo "### flashable zip created at: $WORK_DIRECTORY/out/arch/arm/boot/"
                echo "### flashable zip named: GT-"$DEVICE_NAME"-kernel-los"$LOS_VERSION"-"$LINARO_VERSION"."$NOW".zip";;
   esac
else
   unsupported_response "$PROMPT"
fi

echo "### End of Build Script for $VANITY_DEVICE_TAG! ###"
