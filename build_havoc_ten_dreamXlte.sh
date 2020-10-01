#!/bin/bash  

###
### NOTE:
### you may need to modify the variables below to better suit your personal build environment 
###

#############
# Variable(s)
#############

OS_VERSION="ten"
OS_VERSION_VANITY="3.9"
GCC_VERSION="gcc-10.2.0"
GCC_VERSION_VANITY="$GCC_VERSION-custom"
WORK_DIRECTORY="$HOME/android/dreamXlte-hos-$OS_VERSION"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
LOCAL_REPO_ACCOUNT="fidoedidoe"
LOCAL_MANIFEST_REPO="android_local_manifests_dream2lte"
LOCAL_MANIFEST_BRANCH="havoc-os-$OS_VERSION"
CPU_THREADS=$(nproc --all)
REPO_INIT_FLAG_1="--depth=1"
REPO_INIT_FLAG_2="--no-clone-bundle"
KERNEL_AARCH64_TRIPLE="aarch64-linux-gnu-"
#KERNEL_AARCH64_TRIPLE="aarch64-linux-android-"
KERNEL_ARM_TRIPLE="arm-linux-gnueabi-"
#KERNEL_ARM_TRIPLE="arm-linux-androideabi-"
KERNEL_CLANG_TRIPLE="$KERNEL_AARCH64_TRIPLE"
#CLANG_VERSION="clang-r353983d"
CLANG_VERSION="clang-r370808b"
#CLANG_VERSION="clang-r377782d" #fimc-is-sysfs.c:248:40: error: expression does not compute the number of elements in this array; element type is 'struct ssrm_camera_data', not 'int' [-Werror,-Wsizeof-array-div] if (ret_count > sizeof(SsrmCameraInfo)/sizeof(int))
                               # wl_android.c:6806:22: error: overlapping comparisons always evaluate to false [-Werror,-Wtautological-overlap-compare]  if ((adps_mode < 0) && (1 < adps_mode))
#CLANG_VERSION="clang-r383902c"  # as above, plus: errors sock.c:774:2: error: misleading indentation
#KERNEL_CROSS_COMPILE_DIRECTORY="$WORK_DIRECTORY/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin"
#KERNEL_CROSS_COMPILE_DIRECTORY="$HOME/android/dev/toolchain/aarch64-linux-gnu-8.3-linaro/bin"
#KERNEL_CROSS_COMPILE_DIRECTORY="$HOME/android/dev/toolchain/aarch64-linux-gnu-9.2-original/bin"
#KERNEL_CROSS_COMPILE_DIRECTORY="$HOME/android/dev/toolchain/aarch64-linux-gnu-9.2-custom/bin"
#KERNEL_CROSS_COMPILE_DIRECTORY="$HOME/android/dev/toolchain/aarch64-linux-gnu-9.3-custom/bin"
#KERNEL_CROSS_COMPILE_DIRECTORY="$HOME/android/dev/toolchain/aarch64-linux-android-10.2-ct-ng/bin"
#KERNEL_CROSS_COMPILE_DIRECTORY="$HOME/android/dev/toolchain/aarch64-linux-gnu-10.2-ct-ng/bin"
KERNEL_CROSS_COMPILE_DIRECTORY="$HOME/android/dev/toolchain/aarch64-linux-gnu-10.2-custom/bin"
#KERNEL_CROSS_COMPILE_DIRECTORY="$HOME/android/dev/toolchain/aarch64-linux-gnu-10.2.1-custom/bin"
#KERNEL_CROSS_COMPILE_ARM32_DIRECTORY="$WORK_DIRECTORY/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin"
#KERNEL_CROSS_COMPILE_ARM32_DIRECTORY="$HOME/android/dev/toolchain/arm-linux-gnueabi-9.2-original/bin"
#KERNEL_CROSS_COMPILE_ARM32_DIRECTORY="$HOME/android/dev/toolchain/arm-linux-gnueabi-9.2-custom/bin"
#KERNEL_CROSS_COMPILE_ARM32_DIRECTORY="$HOME/android/dev/toolchain/arm-linux-gnueabi-9.3-custom/bin"
#KERNEL_CROSS_COMPILE_ARM32_DIRECTORY="$HOME/android/dev/toolchain/arm-linux-androideabi-10.2-ct-ng/bin"
KERNEL_CROSS_COMPILE_ARM32_DIRECTORY="$HOME/android/dev/toolchain/arm-linux-gnueabi-10.2-custom/bin"
#KERNEL_CLANG_DIRECTORY="${WORK_DIRECTORY}/prebuilts/clang/host/linux-x86/$CLANG_VERSION/bin"
KERNEL_CLANG_DIRECTORY="/home/gavin/android/dev/toolchain/$CLANG_VERSION/bin"
KERNEL_SOURCE_DIRECTORY="$WORK_DIRECTORY/kernel/samsung/universal8895"
KERNEL_OUT_DIRECTORY="$WORK_DIRECTORY/out"
NOW=$(date +"%Y%m%d")
TIME="/usr/bin/time"
TIME_FORMAT="------------\n The command '%C'\n Completed in [hours:]minutes:seconds \n %E \n------------"
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
  echoMsg "### Error: '$1' was entered, aborting script execution!$" "RED"
  exit 1
}

function parse_parameters() {

   while [[ ${#} -ge 1 ]]; do
       case "${1}" in
           # REQUIRED FLAGS
           "-d"|"--device") shift && DEVICE=${1};;
           "-b"|"--build-type" ) shift && BUILD=${1} ;;

           # OPTIONAL FLAGS
           "-c"|"--ccache" ) USE_CACHE="Y" ;;
           "-g"|"--clang" ) USE_CLANG="Y" ;;
           "-r"|"--refresh-source") REFRESH_SOURCE="Y" ;;

           # HELP!
           "-h"|"--help") help_menu; exitPrompt; exit ;;
       esac
       shift
    done

    #check --device value
    case "${DEVICE}" in
      "dream2lte" ) DEVICE_NAME="dream2lte" ;;
      "dreamlte"  ) DEVICE_NAME="dreamlte" ;;
      "greatlte"  ) DEVICE_NAME="greatlte" ;;
                * ) unsupported_response "--device: ${DEVICE}";;
    esac
    DEVICE_NAME_VANITY="S8 $DEVICE_NAME"

    #check --build value
    case "${BUILD}" in
      "full"  ) BUILD_TYPE="full"
                echoMsg "### BUILD. Full android HOS $OS_VERSION";;
      "kernel") BUILD_TYPE="kernel"
                echoMsg "### BUILD. Kernel for HOS $OS_VERSION";;
     #"twrp"  ) BUILT_TYPE="twrp";;
     #          TWRP_VERSION="3.4.0"
     #          echoMsg "### BUILD. TWRP version $TWRP_VERSION";;
             *) unsupported_response "--build-type ${1}" ;;
    esac

    #check --cache value
    case "${USE_CACHE}" in
      "Y") CCACHE="/usr/bin/ccache";;
        *) CCACHE="";;
    esac

    #check --refresh-source value
    case "${REFRESH_SOURCE}" in
      "Y") SKIP_BUILD_STEPS="N";;
        *) SKIP_BUILD_STEPS="Y";;
    esac

    #check --clang value
    case "${USE_CLANG}" in
      "Y") CLANG="clang";;
        *) CLANG="";;
    esac
}


#####################
# Main body of script
#####################

echoMsg "###"
echoMsg "### Start of build script"
echoMsg "###"

parse_parameters "${@}"

echoMsg "###"
echoMsg "### Building for: $DEVICE_NAME_VANITY" 
echoMsg "###"

if [[ $SKIP_BUILD_STEPS = "N" ]]; then

  echoMsg "### Initialise/Re-base HOS Repo's <Y/n>?" "NEUTRAL"

  #Ensure working directory exists
  mkdir -p "$WORK_DIRECTORY"

  # Change to working directory
  cd "$WORK_DIRECTORY" || exit
	

  if [ ! -d "$WORK_DIRECTORY/$REPO_DIRECTORY" ]; then
    echoMsg "### initialising HOS repo/manifests for first time..."
    $TIME -f "$TIME_FORMAT" repo init -u https://github.com/Havoc-OS/android_manifest.git -b "$OS_VERSION" "$REPO_INIT_FLAG_1" "$REPO_INIT_FLAG_2"
  else
    echoMsg "### HOS repo/manifests exists..."
    echoMsg "### Reverting all local HOS modifications..."
    $TIME -f "$TIME_FORMAT" repo forall -vc "git reset --hard ; git clean -fdx" --quiet
    echoMsg "### All local modifications reverted, local source now aligned to upstream repo!"
  fi
else
  echoMsg "### Skipping build Step (repo init), based on --refresh-source parameter"
fi

if [[ $SKIP_BUILD_STEPS = "N" ]]; then
  PROMPT=""
  echoMsg "### Initialise local_manifest and perform repo sync" "NEUTRAL"

  if [ ! -d "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY" ]; then
    echoMsg "### create 'local_manifest' and re-run repo sync..."
    mkdir -p "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY"
    $TIME -f "$TIME_FORMAT" git clone --depth 1 https://github.com/$LOCAL_REPO_ACCOUNT/$LOCAL_MANIFEST_REPO -b "$LOCAL_MANIFEST_BRANCH" "$LOCAL_MANIFESTS_DIRECTORY"
  else
    echoMsg "### $LOCAL_MANIFESTS_DIRECTORY already exists, skipping git clone"
  fi

  echoMsg "### sync repo with $CPU_THREADS threads..."
  $TIME -f "$TIME_FORMAT" repo sync --jobs="$CPU_THREADS" --quiet --force-sync --no-tags --no-clone-bundle --no-repo-verify
  echoMsg "### sync complete!"
else
  echoMsg "### Skipping Step (repo sync), based on input parameter --refresh-source"
fi

echoMsg "### Prepare device specific code for: $DEVICE_NAME_VANITY <Y/n>?" "NEUTRAL"

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
   echoMsg "### Building kernel, no device specifc settings to add...skipping..."
fi

if [[ $SKIP_BUILD_STEPS = "N" ]]; then
  PROMPT=""
  echoMsg "### Appling patches "

  # wireguard download isn't working within build script: HACK - revist. 
  if [ ! -d "$KERNEL_SOURCE_DIRECTORY"/net/wireguard ]; then
     echoMsg "wireguard: source repo exists, purging..."
     rm -rf "$KERNEL_SOURCE_DIRECTORY"/net/wireguard || exit
  fi 
  echoMsg "wireguard: Downloading latest source..."
  cd "$KERNEL_SOURCE_DIRECTORY" || exit 
  scripts/fetch-latest-wireguard.sh
  echoMsg "wireguard: Downoad complete!"

  cd "$KERNEL_SOURCE_DIRECTORY" || exit
    for PATCH_FILE in ../../../patches/patches/kernel_samsung_universal8895/*.patch; do
    echoMsg "patching file: $KERNEL_SOURCE_DIRECTORY/$PATCH_FILE"
    patch -p 1 < "$PATCH_FILE" || exit
  done
  
  cd "$KERNEL_SOURCE_DIRECTORY" || exit
  echoMsg "### applying $LOCAL_MANIFESTS_DIRECTORY/0001_kernel_makefile.patch"
  patch -p 1 < ../../../$LOCAL_MANIFESTS_DIRECTORY/0001_kernel_makefile.patch || exit

  if [[ $CLANG != "clang" ]]; then
     cd "$KERNEL_SOURCE_DIRECTORY" || exit
     echoMsg "### applying $LOCAL_MANIFESTS_DIRECTORY/0002_arm64_makefile.patch"
     patch -p 1 < ../../../$LOCAL_MANIFESTS_DIRECTORY/0002_arm64_makefile.patch || exit
  fi

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
  echoMsg "### Skipping apply patches, based on input paremeter --refresh-repo"
fi

echoMsg "### Start $DEVICE_NAME_VANITY build process (this step can take some time depending if CC_CACHE is being used)"

case "$BUILD_TYPE" in
 "full")     echoMsg "### Running 'brunch $DEVICE_NAME'..."
             brunch havoc_$DEVICE_NAME-user
             OUT_FILE_NAME="Havoc-OS-v$OS_VERSION_VANITY-$NOW-$DEVICE_NAME-Unofficial.zip"
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

 "recovery") echoMsg "### Running 'mka recoveryimage'..."
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

 "kernel")   echoMsg "### Running kernel build..."
             cd "$KERNEL_SOURCE_DIRECTORY" || exit
             mkdir -p "$KERNEL_OUT_DIRECTORY" || exit
             export LOCALVERSION="-$DEVICE_NAME-$GCC_VERSION"
             export KBUILD_BUILD_USER="fidoedidoe"
             export KBUILD_BUILD_HOST="on-an-underpowered-laptop"
             export ARCH=arm64
             if [[ $CLANG = "clang" ]]; then
                echoMsg "### $CLANG version: $CLANG_VERSION"
                PATH="${KERNEL_CLANG_DIRECTORY}:${KERNEL_CROSS_COMPILE_DIRECTORY}:${KERNEL_CROSS_COMPILE_ARM32_DIRECTORY}:${PATH}"
                #echo $PATH
                export CROSS_COMPILE="$KERNEL_AARCH64_TRIPLE"
                export CROSS_COMPILE_ARM32="$KERNEL_ARM_TRIPLE"
                export CLANG_TRIPPLE="$KERNEL_CLANG_TRIPLE"
                echoMsg "### $CLANG version: $CLANG_VERSION"
                echoMsg "### CLANG_TRIPPLE: $CLANG_TRIPPLE"
                echoMsg "### PATH: $PATH"
             else
                export CROSS_COMPILE="$CCACHE $KERNEL_CROSS_COMPILE_DIRECTORY/$KERNEL_AARCH64_TRIPLE"
                export CROSS_COMPILE_ARM32="$CCACHE $KERNEL_CROSS_COMPILE_ARM32_DIRECTORY/$KERNEL_ARM_TRIPLE"
		export SUBARCH=$ARCH
                echoMsg "### GCC version: $GCC_VERSION_VANITY"
                echoMsg "### SUBARCH=: $SUBARCH"
             fi
             echoMsg "### CROSS_COMPILE: $CROSS_COMPILE"
             echoMsg "### CROSS_COMPILE_ARM32: $CROSS_COMPILE_ARM32"
             echoMsg "### defconfig: exynos8895-${DEVICE_NAME}_defconfig"
	     make O="$KERNEL_OUT_DIRECTORY" clean
             make O="$KERNEL_OUT_DIRECTORY" mrproper
             make O="$KERNEL_OUT_DIRECTORY" ARCH=$ARCH exynos8895-"$DEVICE_NAME"_defconfig
             if [[ $CLANG = "clang" ]]; then
                $TIME -f "$TIME_FORMAT" make -j"$CPU_THREADS" O="$KERNEL_OUT_DIRECTORY" ARCH="$ARCH" CC="$CCACHE $CLANG"
             else
                $TIME -f "$TIME_FORMAT" make -j"$CPU_THREADS" O="$KERNEL_OUT_DIRECTORY" ARCH="$ARCH"
             fi
             OUT_FILE_NAME="$DEVICE_NAME-kernel-hos-$OS_VERSION_VANITY-$GCC_VERSION_VANITY.$NOW.zip"
             if [ -f "$KERNEL_OUT_DIRECTORY"/arch/arm64/boot/Image ]; then
                echoMsg "### building flashable anykernel3 zip file...."
                cp "$KERNEL_OUT_DIRECTORY"/arch/arm64/boot/Image "$KERNEL_SOURCE_DIRECTORY"/anyKernel3
                cp "$KERNEL_OUT_DIRECTORY"/arch/arm64/boot/dtb.img "$KERNEL_SOURCE_DIRECTORY"/anyKernel3
                cd "$KERNEL_SOURCE_DIRECTORY"/anyKernel3 || exit
                zip -r9 kernel.zip ./* -x .git README.md ./*placeholder kernel.zip
                rm Image
                rm dtb.img
                mv kernel.zip "$KERNEL_OUT_DIRECTORY"/arch/arm64/boot/
                cd "$KERNEL_OUT_DIRECTORY"/arch/arm64/boot/ || exit
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

echoMsg "### End of Build Script for $DEVICE_NAME_VANITY! ###"
