#!/bin/bash  

###
### NOTE:
### you may need to modify the variables below to better suit your personal build environment 
###

#############
# Variable(s)
#############

HOS_VERSION="ten"
HOS_VERSION_VANITY="3.9"
LINARO_VERSION_SHORT="gcc-10.2.0"
LINARO_VERSION="$LINARO_VERSION_SHORT-experimental"
WORK_DIRECTORY="$HOME/android/dreamXlte-hos-$HOS_VERSION"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
LOCAL_MANIFEST_REPO="fidoedidoe"
LOCAL_MANIFEST_BRANCH="havoc-os-$HOS_VERSION"
CPU_THREADS=$(nproc --all)
REPO_INIT_FLAG_1="--depth=1"
REPO_INIT_FLAG_2="--no-clone-bundle"
CCACHE="/usr/bin/ccache"
#KERNEL_CROSS_COMPILE="$WORK_DIRECTORY/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
#KERNEL_CROSS_COMPILE="$HOME/android/dev/toolchain/aarch64-linux-gnu-8.3-linaro/bin/aarch64-linux-gnu-"
#KERNEL_CROSS_COMPILE="$HOME/android/dev/toolchain/aarch64-linux-gnu-9.2-original/bin/aarch64-linux-gnu-"
#KERNEL_CROSS_COMPILE="$HOME/android/dev/toolchain/aarch64-linux-gnu-9.2-custom/bin/aarch64-linux-gnu-"
#KERNEL_CROSS_COMPILE="$HOME/android/dev/toolchain/aarch64-linux-gnu-9.3-custom/bin/aarch64-linux-gnu-"
#KERNEL_CROSS_COMPILE="$HOME/android/dev/toolchain/aarch64-linux-android-10.2-ct-ng/bin/aarch64-linux-android-"
#KERNEL_CROSS_COMPILE="$HOME/android/dev/toolchain/aarch64-linux-gnu-10.2-ct-ng/bin/aarch64-linux-android-"
KERNEL_CROSS_COMPILE="$HOME/android/dev/toolchain/aarch64-linux-gnu-10.2-custom/bin/aarch64-linux-gnu-"
#KERNEL_CROSS_COMPILE="$HOME/android/dev/toolchain/aarch64-linux-gnu-10.2.1-custom/bin/aarch64-linux-gnu-"
#KERNEL_CROSS_COMPILE_ARM32="$WORK_DIRECTORY/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"
#KERNEL_CROSS_COMPILE_ARM32="$HOME/android/dev/toolchain/arm-linux-gnueabi-9.2-original/bin/arm-linux-gnueabi-"
#KERNEL_CROSS_COMPILE_ARM32="$HOME/android/dev/toolchain/arm-linux-gnueabi-9.2-custom/bin/arm-linux-gnueabi-"
#KERNEL_CROSS_COMPILE_ARM32="$HOME/android/dev/toolchain/arm-linux-gnueabi-9.3-custom/bin/arm-linux-gnueabi-"
#KERNEL_CROSS_COMPILE_ARM32="$HOME/android/dev/toolchain/arm-linux-androideabi-10.2-ct-ng/bin/arm-linux-androideabi--"
KERNEL_CROSS_COMPILE_ARM32="$HOME/android/dev/toolchain/arm-linux-gnueabi-10.2-custom/bin/arm-linux-gnueabi-"
#KERNEL_CLANG_TRIPLE="$HOME/android/dev/toolchain/aarch64-linux-gnu-10.2/bin/aarch64-linux-gnu-"
#KERNEL_CLANG_TRIPLE="$HOME/android/dev/toolchain/aarch64-linux-gnu-9.2/bin/aarch64-linux-gnu-"
#KERNEL_DIR="$WORK_DIRECTORY/kernel"
KERNEL_OUT_DIR="$WORK_DIRECTORY/out"
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

DEVICE_NAME_VANITY="S8 $DEVICE_NAME"
DEVICE_NAME="${DEVICE_NAME,,}"

echoMsg "###" "YELLOW"
echoMsg "### Start of build script" "YELLOW" 
echoMsg "###"
echoMsg "### Building for: $DEVICE_NAME_VANITY" 
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
echoMsg "### (5/7) Prepare device specific code for: $DEVICE_NAME_VANITY <Y/n>?" "NEUTRAL"
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

   cd "$WORK_DIRECTORY" || exit

   #echoMsg "### set environment var to stop issues with prebuilts/misc/.../flex"
   export LC_ALL=C

   echoMsg "### preparing device specific code..."
   # shellcheck disable=SC1091
   source build/envsetup.sh

   breakfast havoc_$DEVICE_NAME-user

   echoMsg "### running croot..."
   croot

   echoMsg "### Do you want to clear old build output (if any exists), select Y when new code added <N/y>"
   # shellcheck disable=SC2034
   read -r -p "(automatically continues unprompted after 5 seconds): " -t 5 -e -i N PROMPT
   echo
   if [ -z "$PROMPT" ]; then
     PROMPT="N"
   fi
   if [[ $PROMPT =~ ^[Yy]$ ]]; then
      mka clobber
   fi
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

  # wireguard download isn't working within build script: HACK - revist. 
  if [ ! -d "$WORK_DIRECTORY"/kernel/samsung/universal8895/net/wireguard ]; then
     echoMsg "wireguard: source repo exists, purging..."
     rm -rf "$WORK_DIRECTORY"/kernel/samsung/universal8895/net/wireguard || exit
  fi 
  echoMsg "wireguard: Downloading latest source..."
  cd "$WORK_DIRECTORY"/kernel/samsung/universal8895 || exit 
  scripts/fetch-latest-wireguard.sh
  echoMsg "wireguard: Downoad complete!"

  cd "$WORK_DIRECTORY"/kernel/samsung/universal8895 || exit
    for PATCH_FILE in ../../../patches/patches/kernel_samsung_universal8895/*.patch; do
    echoMsg "patching file: kernel/samsung/universal8895/$PATCH_FILE"
    patch -p 1 < "$PATCH_FILE" 
  done
  
  cd "$WORK_DIRECTORY"/kernel/samsung/universal8895 || exit
  echoMsg "### applying $LOCAL_MANIFESTS_DIRECTORY/0001_kernel_makefile.patch"
  patch -p 1 < ../../../$LOCAL_MANIFESTS_DIRECTORY/0001_kernel_makefile.patch

  cd "$WORK_DIRECTORY"/kernel/samsung/universal8895 || exit
  echoMsg "### applying $LOCAL_MANIFESTS_DIRECTORY/0002_arm64_makefile.patch"
  patch -p 1 < ../../../$LOCAL_MANIFESTS_DIRECTORY/0002_arm64_makefile.patch

  # not needed, HAVOC-OS/device_samsung_universal8895-common repo has these patches applied already
  #cd "$WORK_DIRECTORY"/device/samsung/universal8895-common || exit
  #  for PATCH_FILE in ../../../patches/patches/device_samsung_universal8895-common/*.patch; do
  #  echoMsg "patching file: device/samsung/universal8895-common/$PATCH_FILE"
  #     patch -p 1 < "$PATCH_FILE"
  #  fi
  #done 

  cd "$WORK_DIRECTORY" || exit
  echoMsg "### Patches applied!"
else
  echoMsg "### Skipping Step #6 (patch), based on earlier input."
fi

PROMPT=""
echoMsg "### (7/7) Start $DEVICE_NAME_VANITY build process (this step can take some time depending on CC_CACHE) <Y/n>?" "NEUTRAL"
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
                brunch havoc_$DEVICE_NAME-user
                OUT_FILE_NAME="Havoc-OS-v$HOS_VERSION_VANITY-$NOW-$DEVICE_NAME-Unofficial.zip"
                if [ -f "$WORK_DIRECTORY"/out/target/product/"$DEVICE_NAME"/"$OUT_FILE_NAME" ]; then
                   echoMsg "### Custom ROM flashable zip created at: $WORK_DIRECTORY/out/target/product/$DEVICE_NAME/" "GREEN"
                   echoMsg "### Custom ROM flashable zip name: $OUT_FILE_NAME" "GREEN"
                else
		   echoMsg "###" "RED"
		   echoMsg "### Custom ROM Compile failure" "RED"
                   echoMsg "### (script cannot find the file '$OUT_FILE_NAME')" "RED"
                   echoMsg "### Script aborting." "RED"
		   echoMsg "###" "RED"
		   exit
                fi;;

    "recovery") echoMsg "### Starting $BUILD_TYPE build, running 'mka recoveryimage'..."
                export WITH_TWRP="true"
                mka recoveryimage
                cd "$WORK_DIRECTORY"/out/target/product/"$DEVICE_NAME"/ || exit
                OUT_FILE_NAME="twrp-$TWRP_VERSION-$DEVICE_NAME-$NOW.img"
                if [ -f recovery.img ]; then
                   mv recovery.img "$OUT_FILE_NAME"
                   echoMsg "### TWRP flashable image created at: $WORK_DIRECTORY/out/target/product/$DEVICE_NAME/" "GREEN"
                   echoMsg "### TWRP flashable image name: $OUT_FILE_NAME" "GREEN"
                else
		   echoMsg "###" "RED"
		   echoMsg "### TWRP Compile failure (script cannot find the file 'recovery.img')!! Script aborting." "RED"
		   echoMsg "###" "RED"
		   exit
                fi;;

    "kernel")   echoMsg "### Starting $BUILD_TYPE build..."
                export CROSS_COMPILE="$CCACHE $KERNEL_CROSS_COMPILE"
                export CROSS_COMPILE_ARM32="$CCACHE $KERNEL_CROSS_COMPILE_ARM32"
                # export CLANG_TRIPPLE="$CCACHE $KERNEL_CLANG_TRIPLE"
                export ARCH=arm64
		export SUBARCH=arm64
                export LOCALVERSION="-$DEVICE_NAME-$LINARO_VERSION_SHORT"
                export KBUILD_BUILD_USER="fidoedidoe"
                export KBUILD_BUILD_HOST="on-an-underpowered-laptop"
                cd "$WORK_DIRECTORY"/kernel/samsung/universal8895/ || exit
                mkdir -p "$KERNEL_OUT_DIR"
                echoMsg "CROSS_COMPILE: $CROSS_COMPILE"
                echoMsg "defconfig: exynos8895-${DEVICE_NAME}_defconfig"
                #cd "$KERNEL_DIR" || exit
	        make O="$KERNEL_OUT_DIR" clean
                make O="$KERNEL_OUT_DIR" mrproper
                #make O="$KERNEL_OUT_DIR" exynos8895-"$DEVICE_NAME"_defconfig
                make O="$KERNEL_OUT_DIR" ARCH=$ARCH exynos8895-"$DEVICE_NAME"_defconfig
                #PATH="$HOME/android/dev/toolchain/clang_11.04_r399163/bin:${PATH}"
                #$TIME -f "$TIME_FORMAT" make -j"$CPU_THREADS" O="$KERNEL_OUT_DIR" ARCH="$ARCH" CC=clang
                $TIME -f "$TIME_FORMAT" make -j"$CPU_THREADS" O="$KERNEL_OUT_DIR" ARCH="$ARCH"
                OUT_FILE_NAME="$DEVICE_NAME-kernel-hos-$VANITY_HOS_VERSION-$LINARO_VERSION.$NOW.zip"
                if [ -f "$KERNEL_OUT_DIR"/arch/arm64/boot/Image.gz ]; then
                   cp "$KERNEL_OUT_DIR"/arch/arm64/boot/Image.gz "$WORK_DIRECTORY"/kernel/samsung/universal8895/anyKernel3
                   cp "$KERNEL_OUT_DIR"/arch/arm64/boot/dtb.img "$WORK_DIRECTORY"/kernel/samsung/universal8895/anyKernel3
                   echoMsg "### building flashable anykernel3 zip file...."
                   cd "$WORK_DIRECTORY"/kernel/samsung/universal8895/anyKernel3 || exit
                   zip -r9 kernel.zip ./* -x .git README.md ./*placeholder kernel.zip
                   rm Image.gz
                   rm dtb.img
                   mv kernel.zip "$KERNEL_OUT_DIR"/arch/arm64/boot/
                   cd "$KERNEL_OUT_DIR"/arch/arm64/boot/ || exit
                   mv kernel.zip "$OUT_FILE_NAME"
                   echoMsg "### flashable kernel zip created at: $WORK_DIRECTORY/out/arch/arm64/boot/" "GREEN"
                   echoMsg "### flashable kernel zip named: $OUT_FILE_NAME" "GREEN"
               else
		   echoMsg "###" "RED"
		   echoMsg "### Kernel Compile failure (script cannot find file 'Image.gz')!! Script aborting." "RED"
		   echoMsg "###" "RED"
		   exit
               fi;;
   esac
else
   unsupported_response "$PROMPT"
fi

echoMsg "### End of Build Script for $DEVICE_NAME_VANITY! ###"
