#!/bin/bash  

###
### NOTE:
### you may need to modify the variables below to better suit your personal build environment 
###

#############
# Variable(s)
#############

HOS_VERSION="ten"
VANITY_HOS_VERSION="3.9"
LINARO_VERSION_SHORT="gcc-10.2.0"
LINARO_VERSION="$LINARO_VERSION_SHORT-experimental"
WORK_DIRECTORY="$HOME/android/$DEVICE_NAME-hos-$HOS_VERSION"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_FILE='local_manifest.xml'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
LOCAL_MANIFEST_REPO="fidoedidoe"
LOCAL_MANIFEST_BRANCH="havoc-os-$HOS_VERSION"
CPU_THREADS=$(nproc --all)
GITHUB_REPO="Havoc-OS"
ANDROID_MANIFEST_REPO="android_manifest"
ANDROID_MANIFEST_BRANCH="$HOS_VERSION"
ANDROID_MANIFEST_DIRECTORY=""
REPO_INIT_FLAG_1="--depth=1"
REPO_INIT_FLAG_2="--no-clone-bundle"
SLEEP_DURATION="1"
CCACHE="/usr/bin/ccache"
KERNEL_CROSS_COMPILE="$WORK_DIRECTORY/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
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

if [[ -n "$1" ]]; then
  DEVICE_NAME="${1^^}"
  if [[ "$DEVICE_NAME" =~ ^(DREAMLTE|DREAM2LTE|GREATLTE)$ ]]; then
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

VANITY_DEVICE_TAG="S8 $DEVICE_NAME"
DEVICE_NAME="${DEVICE_NAME,,}"

echoMsg "###" "YELLOW"
echoMsg "### Start of build script" "YELLOW" 
echoMsg "###"
echoMsg "### Building for: $VANITY_DEVICE_TAG" 
echoMsg "###"

PROMPT=""
echoMsg "### (1/7) Which build type (ROM, Recovery, Kernel? "
echoMsg "###       #1. Full HOS $HOS_VERSION Build"
# echoMsg "###       #2. TWRP Recovery Only"
echoMsg "###       #3. HOS Kernel Only"
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
   #"2") echoMsg "### Selected: TWRP Recovery Build..."
   #     BUILD_TYPE="recovery";;
   "3") echoMsg "### Selected LineageOS Kernel Build..."
        BUILD_TYPE="kernel";;    
  esac	  
else
  unsupported_response "$PROMPT"
fi

PROMPT=""
echoMsg "### (2/7) Do you want to skip step: #3 (repo init), #4 (repo sync) & #6 (patch)? <Y/n>?" "NEUTRAL"
echoMsg "Only select 'Y' if your running back to back builds for the same device" "RED"
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
  echoMsg "### (3/7) Initialise/Re-base HOS Repo's <Y/n>?" "NEUTRAL"
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
    echoMsg "### initialising HOS repo/manifests for first time..."
    $TIME -f "$TIME_FORMAT" repo init -u https://github.com/Havoc-OS/android_manifest.git -b "$HOS_VERSION" "$REPO_INIT_FLAG_1" "$REPO_INIT_FLAG_2"
  else
    echoMsg "### HOS repo/manifests exists..."
    echoMsg "### Reverting all local HOS modifications..."
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
    $TIME -f "$TIME_FORMAT" git clone --depth 1 https://github.com/$LOCAL_MANIFEST_REPO/$LOCAL_MANIFEST_REPO -b "$LOCAL_MANIFEST_BRANCH"
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
   #cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412 || exit

   #we only got cm-14.1-custom earlier. now get standard cm-14.1 branch 
   #git fetch github cm-14.1

   #git checkout github/cm-14.1 -- Makefile

   #cd "$WORK_DIRECTORY" || exit

   #echoMsg "### set environment var to stop issues with prebuilts/misc/.../flex"
   export LC_ALL=C

   echoMsg "### preparing device specific code..."
   # shellcheck disable=SC1091
   source build/envsetup.sh

   breakfast havoc_$DEVICE_NAME-userdebug

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

  ##  - Temp  - fix patches below ##
  ##cd "$WORK_DIRECTORY" || exit
  ##if [ -f kernel/samsung/universal8895/arch/arm64/configs/exynos8895_dreamlte_dream2lte_defconfig ]; then
  ##   if [ ! -f kernel/samsung/universal8895/arch/arm64/configs/exynos8895-dream2lte_defconfig ]; then
  ##      cp kernel/samsung/universal8895/arch/arm64/configs/exynos8895_dreamlte_dream2lte_defconfig kernel/samsung/universal8895/arch/arm64/configs/exynos8895-dream2lte_defconfig
  ##   fi
  ##fi 

  cd "$WORK_DIRECTORY"/kernel/samsung/universal8895 || exit
    for PATCH_FILE in ../../../patches/patches/kernel_samsung_universal8895/*.patch; do
    echoMsg "patching file: kernel/samsung/universal8895/$PATCH_FILE"
    patch -p 1 < "$PATCH_FILE" 
  done 

  # not needed, HAVOC-OS repos have these patches applied already
  #cd "$WORK_DIRECTORY"/device/samsung/universal8895-common || exit
  #  for PATCH_FILE in ../../../patches/patches/device_samsung_universal8895-common/*.patch; do
  #  echoMsg "patching file: device/samsung/universal8895-common/$PATCH_FILE"
  #     patch -p 1 < "$PATCH_FILE"
  #  fi
  #done 

  # wireguard download isn't working within build script: HACK - revist. 
  if [ ! -f "$WORK_DIRECTORY"/kernel/samsung/universal8895/net ]; then
     echoMsg "wireguard: source repo exists, purging..."
     rm -rf "$WORK_DIRECTORY"/kernel/samsung/universal8895/net || exit
  fi 
  echoMsg "wireguard: Downloading latest source..."
  cd "$WORK_DIRECTORY"/kernel/samsung/universal8895 || exit 
  scripts/fetch-latest-wireguard.sh
  echoMsg "wireguard: Downoad complete!"
  
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
                brunch havoc_$DEVICE_NAME-userdebug
                if [ -f "$WORK_DIRECTORY"/out/target/product/"$DEVICE_NAME"/hos-"$HOS_VERSION"-"$NOW"-UNOFFICIAL-"$DEVICE_NAME".zip ]; then
                   echoMsg "### Custom ROM flashable zip created at: $WORK_DIRECTORY/out/target/product/$DEVICE_NAME/" "GREEN"
                   echoMsg "### Custom ROM flashable zip name: hos-$HOS_VERSION-$NOW-UNOFFICIAL-$DEVICE_NAME.zip" "GREEN"
                else
		   echoMsg "###" "RED"
		   echoMsg "### Custom ROM Compile failure" "RED"
                   echoMsg "### (script cannot find the file 'hos-$HOS_VERSION-$NOW-UNOFFICIAL-$DEVICE_NAME.zip')!!""RED"
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
                cd "$WORK_DIRECTORY"/kernel/samsung/universal8895/ || exit
                mkdir -p "$WORK_DIRECTORY"/out
                echoMsg "CROSS_COMPILE: $CROSS_COMPILE"
                echoMsg "defconfig: exynos8895-${DEVICE_NAME}_defconfig"
	        make O="$WORK_DIRECTORY"/out clean
                make O="$WORK_DIRECTORY"/out mrproper
                make O="$WORK_DIRECTORY"/out exynos8895-"$DEVICE_NAME"_defconfig
                $TIME -f "$TIME_FORMAT" make O="$WORK_DIRECTORY"/out -j"$CPU_THREADS"
                if [ -f "$WORK_DIRECTORY"/out/arch/arm/boot/zImage ]; then
                   cp "$WORK_DIRECTORY"/out/arch/arm/boot/zImage "$WORK_DIRECTORY"/kernel/samsung/universal8895/anyKernel3
                   echoMsg "### building flashable anykernel3 zip file...."
                   cd "$WORK_DIRECTORY"/kernel/samsung/universal8895/anyKernel3 || exit
                   zip -r9 kernel.zip ./* -x .git README.md ./*placeholder kernel.zip
                   rm zImage
                   mv kernel.zip "$WORK_DIRECTORY"/out/arch/arm/boot/
                   cd "$WORK_DIRECTORY"/out/arch/arm/boot/ || exit
                   mv kernel.zip "$DEVICE_NAME"-kernel-hos-"$VANITY_HOS_VERSION"-"$LINARO_VERSION"."$NOW".zip
                   echoMsg "### flashable kernel zip created at: $WORK_DIRECTORY/out/arch/arm/boot/" "GREEN"
                   echoMsg "### flashable kernel zip named: $DEVICE_NAME-kernel-hos$VANITY_HOS_VERSION-$LINARO_VERSION.$NOW.zip" "GREEN"
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
