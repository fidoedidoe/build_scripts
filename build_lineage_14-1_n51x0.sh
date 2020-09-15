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
LINARO_VERSION_SHORT="gcc-10.2.0"
LINARO_VERSION="$LINARO_VERSION_SHORT-cortex-a9-neon"
WORK_DIRECTORY="$HOME/android/n51x0-los-$LOS_VERSION"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
CPU_THREADS=$(nproc --all)
LOS_REVISION="$LOS_PREFIX-$LOS_VERSION"
GITHUB_REPO="fidoedidoe"
MANIFEST_REPO="android_.repo_local_manifests_gt-n51x0"
MANIFEST_BRANCH="$LOS_PREFIX-$LOS_VERSION"
REPO_INIT_FLAG_1="--depth=1"
REPO_INIT_FLAG_2="--no-clone-bundle"
SLEEP_DURATION="1"
CCACHE="/usr/bin/ccache"
KERNEL_CROSS_COMPILE="$WORK_DIRECTORY/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-linux-androideabi-"
NOW=$(date +"%Y%m%d")
TIME="/usr/bin/time"
TIME_FORMAT="------------\n The command '%C'\n Completed in [hours:]minutes:seconds \n %E \n------------"
TWRP_VERSION="3.4.0"
SKIP_BUILD_STEPS="N"

#############
# Function(s)
#############

echoMsg() {

  COLOUR_RED="\033[0;31m"
  COLOUR_GREEN="\033[1;32m"
  COLOUR_YELLOW="\033[1;33m"
  COLOUR_NEUTRAL="\033[0m"

  MSG=${1:-}

  COLOUR=${2:-}

  case "$COLOUR" in
     "NEUTRAL"  ) COLOUR=${COLOUR_NEUTRAL};;
     "GREEN"    ) COLOUR=${COLOUR_GREEN};;
     "RED"      ) COLOUR=${COLOUR_RED};;
     "YELLOW"|* ) COLOUR=${COLOUR_YELLOW};;
  esac  

  ARG1=${3:-}

  echo -e "$ARG1" "${COLOUR}${MSG}${COLOUR_NEUTRAL}"
}

unsupported_response () {
  echoMsg "### Response: '$1' was entered, aborting script execution!$" "RED"
  exit 1
}

#####################
# Main body of script
#####################
echoMsg "###" "YELLOW"
echoMsg "### Start of build script" "YELLOW" 

if [[ -n "$1" ]]; then
  DEVICE_NAME="${1^^}"
  if [[ "$DEVICE_NAME" =~ ^(N5100|N5110|N5120)$ ]]; then
     echoMsg "###"
  else
     echoMsg "###" "RED"
     echoMsg "### The passed parameter $DEVICE_NAME is not supported" "RED"
     echoMsg "###" "RED"
     exit
  fi
else
  DEVICE_NAME="N5110"
  echoMsg "###"
  echoMsg "### No passed parameter $DEVICE_NAME assummed"
  echoMsg "###"
fi

VANITY_DEVICE_TAG="Samsung Galaxy Note 8.0 (GT-$DEVICE_NAME)"
DEVICE_NAME="${DEVICE_NAME,,}"

echoMsg "### Building for: $VANITY_DEVICE_TAG" 
echoMsg "###"

PROMPT=""
echoMsg "### (1/7) Which build type (ROM, Recovery, Kernel? "
echoMsg "###       #1. Full LineageOS $LOS_VERSION Build"
echoMsg "###       #2. TWRP Recovery Only"
echoMsg "###       #3. LineageOS Kernel Only"
echoMsg "### Enter build choice <1/2/3>?" "NEUTRAL"
read -r -p "(automatically continues unprompted after 15 seconds):" -t 15 -e -i 1 PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="1"
fi

if [[ "$PROMPT" =~ ^(1|2|3)$ ]]; then
  case "$PROMPT" in
   "1") echoMsg "### Selected: Full LineageOS ROM build..."
        BUILD_TYPE="full";;
   "2") echoMsg "### Selected: TWRP Recovery Build..."
        BUILD_TYPE="recovery";;
   "3") echoMsg "### Selected LineageOS Kernel Build..."
        BUILD_TYPE="kernel";;    
  esac	  
else
  unsupported_response "$PROMPT"
fi

PROMPT=""
echoMsg "### (2/7) Do you want to skip step: #3 (repo init), #4 (repo sync) & #6 (patch)? <Y/n>?" "NEUTRAL"
echoMsg "Only select 'Y' if your running back to back builds for the same device" "NEUTRAL"
read -r -p "(automatically continues unprompted after 5 seconds): " -t 5 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="N"
fi

if [[ ! $PROMPT =~ ^[YyNn]$ ]]; then
  unsupported_response "$PROMPT"
fi

if [[ $PROMPT =~ ^[Yy]$ ]]; then
  SKIP_BUILD_STEPS="Y"
fi


if [[ $SKIP_BUILD_STEPS = "N" ]]; then

  PROMPT=""
  echoMsg "### (3/7) Initialise/Re-base LOS Repo's <Y/n>?" "NEUTRAL"
  read -r -p "(automatically continues unprompted after 1 seconds): " -t 1 -e -i Y PROMPT
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
    echoMsg "### initialising LOS repo/manifests for first time..."
    $TIME -f "$TIME_FORMAT" repo init -u https://github.com/LineageOS/android.git -b "$LOS_REVISION" "$REPO_INIT_FLAG_1" "$REPO_INIT_FLAG_2"
  else
    echoMsg "### LOS repo/manifests exists..."
    echoMsg "### Reverting all local LOS modifications..."
    $TIME -f "$TIME_FORMAT" repo forall -vc "git reset --hard ; git clean -fdx" --quiet
    echoMsg "### All local modifications reverted, local source now aligned to upstream repo!"
  fi
else
  echoMsg "### Skipping Step #3 (repo init), based on earlier input."
fi

if [[ $SKIP_BUILD_STEPS = "N" ]]; then
  PROMPT=""
  echoMsg "### (4/7) Initialise local_manifest and perform repo sync" "NEUTRAL"
  echoMsg "(initial repo sync sync will take an age) <Y/n>?" "NEUTRAL"
  read -r -p "(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
  echo
  if [ -z "$PROMPT" ]; then
    PROMPT="Y"
  fi
  if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
    unsupported_response "$PROMPT"
  fi

  if [ ! -d "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY" ]; then
    echoMsg "### create 'local_manifest' and re-run repo sync..."
    mkdir -p "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY"
    $TIME -f "$TIME_FORMAT" git clone --depth 1 https://github.com/$GITHUB_REPO/$MANIFEST_REPO -b "$MANIFEST_BRANCH" .repo/local_manifests
  else
    echoMsg "### $LOCAL_MANIFESTS_DIRECTORY already exists, skipping git clone"
  fi

  echoMsg "### sync repo with $CPU_THREADS threads..."
  $TIME -f "$TIME_FORMAT" repo sync --jobs="$CPU_THREADS" --quiet --force-sync --no-tags --no-clone-bundle --no-repo-verify
  echoMsg "### sync complete!"
else
  echoMsg "### Skipping Step #4 (repo sync), based on earlier input."
fi

PROMPT=""
echoMsg "### (5/7) Prepare device specific code for: $VANITY_DEVICE_TAG <Y/n>?" "NEUTRAL"
read -r -p "(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  unsupported_response "$PROMPT"
fi

#The following is unecessary for kernel build
if [[ ! $BUILD_TYPE = "kernel" ]]; then

   #In order to build a full rom with the kernel cm-14.1-custom branch
   #the toolchain specific optimisations need to be revoked (from Makefile). Easiest 
   #method to do this was to revert to an earlier version of the impacted file(s)
   #from commit "O3 plus lots of optimization flags"    

   #echo "### we're building "$BUILD_TYPE", revert build flag optimisations in Makefile"
   cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412 || exit

   #we only got cm-14.1-custom earlier. now get standard cm-14.1 branch 
   git fetch github cm-14.1

   git checkout github/cm-14.1 -- Makefile

   cd "$WORK_DIRECTORY" || exit

   echoMsg "### set environment var to stop issues with prebuilts/misc/.../flex"
   export LC_ALL=C

   echoMsg "### preparing device specific code..."
   # shellcheck disable=SC1091
   source build/envsetup.sh

   #During recovery build (TWRP) i started hitting SEPolicy issues
   #relating to permissive kernel & building with user, switching to userdebug mitigated this.  
   case "$BUILD_TYPE" in
      "recovery") breakfast lineage_$DEVICE_NAME-userdebug;;
      *) breakfast lineage_$DEVICE_NAME-user;;
   esac

   echoMsg "### running croot..."
   croot

   echoMsg "### clearing old build output (if any exists)"
   mka clobber
   echoMsg "### Device specific code prepared!"
else
   echoMsg "### Building kernel, nothing to do here!"
fi

cd "$WORK_DIRECTORY" || exit

if [[ $SKIP_BUILD_STEPS = "N" ]]; then
  PROMPT=""
  echoMsg "### (6/7) Apply patche(s) <Y/n>?" "NEUTRAL"
  read -r -p "(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
  echo
  if [ -z "$PROMPT" ]; then
    PROMPT="Y"
  fi
  if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
    unsupported_response "$PROMPT"
  fi

  cd "$WORK_DIRECTORY"/frameworks/base || exit
  echoMsg "### applying patch device/samsung/$DEVICE_NAME/patch/note-8-nougat-mtp-crash.patch"
  patch -p 1 < ../../device/samsung/$DEVICE_NAME/patch/note-8-nougat-mtp-crash.patch
  sleep $SLEEP_DURATION

  cd "$WORK_DIRECTORY"/external/wpa_supplicant_8/wpa_supplicant || exit
  echoMsg "### applying $LOCAL_MANIFESTS_DIRECTORY/0001_external_wpa-supplicant-8_wpa-supplicant_wpa-supplicant-template.patch"
  patch -p 1 < ../../../$LOCAL_MANIFESTS_DIRECTORY/0001_external_wpa-supplicant-8_wpa-supplicant_wpa-supplicant-template.patch
  sleep $SLEEP_DURATION

  cd "$WORK_DIRECTORY"/build/core || exit
  echoMsg "### applying $LOCAL_MANIFESTS_DIRECTORY/0005-build-core-Makefile.patch"
  patch -p 1 < ../../$LOCAL_MANIFESTS_DIRECTORY/0005-build-core-Makefile.patch
  sleep $SLEEP_DURATION

  case "$BUILD_TYPE" in
    "full") cd "$WORK_DIRECTORY" || exit
            echoMsg "### applying $LOCAL_MANIFESTS_DIRECTORY/0002-custom-toolchain-optimisation.patch"
            patch -p 1 < $LOCAL_MANIFESTS_DIRECTORY/0002-custom-toolchain-optimisation.patch;;
    "kernel") 
            if [[ $DEVICE_NAME = "n5100" ]]; then
               cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3 || exit
               echoMsg "### applying $LOCAL_MANIFESTS_DIRECTORY/0003-AnyKernel3-N5100-Device-Names.patch"
               patch -p 1 < ../../../../$LOCAL_MANIFESTS_DIRECTORY/0003-AnyKernel3-N5100-Device-Names.patch
               sleep $SLEEP_DURATION
            fi
            if [[ $DEVICE_NAME = "n5120" ]]; then
               cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3 || exit
               sleep $SLEEP_DURATION
               echoMsg "### applying $LOCAL_MANIFESTS_DIRECTORY/0004-AnyKernel3-N5120-Device-Names.patch"
               patch -p 1 < ../../../../$LOCAL_MANIFESTS_DIRECTORY/0004-AnyKernel3-N5120-Device-Names.patch
               sleep $SLEEP_DURATION
            fi;;
  esac

  cd "$WORK_DIRECTORY" || exit
  echoMsg "### Patches applied!"
else
  echoMsg "### Skipping Step #6 (patch), based on earlier input."
fi

PROMPT=""
echoMsg "### (7/7) Start $VANITY_DEVICE_TAG build process (this step can take some time depending on CC_CACHE) <Y/n>?" "NEUTRAL"
# shellcheck disable=SC2034
read -r -p "(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ $PROMPT =~ ^[Yy]$ ]]; then
   PROMPT=""
   case "$BUILD_TYPE" in
    "full")     echoMsg "### Starting $BUILD_TYPE build, running 'brunch $DEVICE_NAME'..."
                brunch lineage_$DEVICE_NAME-user
                if [ -f "$WORK_DIRECTORY"/out/target/product/"$DEVICE_NAME"/los-"$LOS_VERSION"-"$NOW"-UNOFFICIAL-"$DEVICE_NAME".zip ]; then
                   echoMsg "### Custom ROM flashable zip created at: $WORK_DIRECTORY/out/target/product/$DEVICE_NAME/" "GREEN"
                   echoMsg "### Custom ROM flashable zip name: los-$LOS_VERSION-$NOW-UNOFFICIAL-$DEVICE_NAME.zip" "GREEN"
                else
		   echoMsg "###" "RED"
		   echoMsg "### Custom ROM Compile failure" "RED"
                   echoMsg "### (script cannot find the file 'los-$LOS_VERSION-$NOW-UNOFFICIAL-$DEVICE_NAME.zip')!!""RED"
                   echoMsg "### Script aborting." "RED"
		   echoMsg "###" "RED"
		   exit
                fi;;

    "recovery") echoMsg "### Starting $BUILD_TYPE build, running 'mka recoveryimage'..."
                export WITH_TWRP="true"
                mka recoveryimage
                cd "$WORK_DIRECTORY"/out/target/product/"$DEVICE_NAME"/ || exit 
                if [ -f recovery.img ]; then
                   mv recovery.img twrp-"$TWRP_VERSION"-"$DEVICE_NAME"-"$NOW".img
                   echoMsg "### TWRP flashable image created at: $WORK_DIRECTORY/out/target/product/$DEVICE_NAME/" "GREEN"
                   echoMsg "### TWRP flashable image name: twrp-$TWRP_VERSION-$DEVICE_NAME-$NOW.img" "GREEN"
                else
		   echoMsg "###" "RED"
		   echoMsg "### TWRP Compile failure (script cannot find the file 'recovery.img')!! Script aborting." "RED"
		   echoMsg "###" "RED"
		   exit
                fi;;

    "kernel")   echoMsg "### Starting $BUILD_TYPE build..."
                export CROSS_COMPILE="$CCACHE $KERNEL_CROSS_COMPILE"
		export ARCH=arm
		export SUBARCH=arm
                export LOCALVERSION="-$DEVICE_NAME-$LINARO_VERSION_SHORT"
                export KBUILD_BUILD_USER="fidoedidoe"
                export KBUILD_BUILD_HOST="on-an-underpowered-laptop"
                cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/ || exit
                mkdir -p "$WORK_DIRECTORY"/out
                echoMsg "CROSS_COMPILE: $CROSS_COMPILE"
                echoMsg "defconfig: lineageos_${DEVICE_NAME}_defconfig"
	        make O="$WORK_DIRECTORY"/out clean
                make O="$WORK_DIRECTORY"/out mrproper
                make O="$WORK_DIRECTORY"/out lineageos_"$DEVICE_NAME"_defconfig
                $TIME -f "$TIME_FORMAT" make O="$WORK_DIRECTORY"/out -j"$CPU_THREADS"
                if [ -f "$WORK_DIRECTORY"/out/arch/arm/boot/zImage ]; then
                   cp "$WORK_DIRECTORY"/out/arch/arm/boot/zImage "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3
                   echoMsg "### building flashable anykernel3 zip file...."
                   cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3 || exit
                   zip -r9 kernel.zip ./* -x .git README.md ./*placeholder kernel.zip
                   rm zImage
                   mv kernel.zip "$WORK_DIRECTORY"/out/arch/arm/boot/
                   cd "$WORK_DIRECTORY"/out/arch/arm/boot/ || exit
                   mv kernel.zip "$DEVICE_NAME"-kernel-los-"$LOS_VERSION"-"$LINARO_VERSION"."$NOW".zip
                   echoMsg "### flashable kernel zip created at: $WORK_DIRECTORY/out/arch/arm/boot/" "GREEN"
                   echoMsg "### flashable kernel zip named: $DEVICE_NAME-kernel-los$LOS_VERSION-$LINARO_VERSION.$NOW.zip" "GREEN"
               else
		   echoMsg "###" "RED"
		   echoMsg "### Kernel Compile failure (script cannot find file 'zImage')!! Script aborting." "RED"
		   echoMsg "###" "RED"
		   exit
               fi;;
   esac
else
   unsupported_response "$PROMPT"
fi

echoMsg "### End of Build Script for $VANITY_DEVICE_TAG! ###"
