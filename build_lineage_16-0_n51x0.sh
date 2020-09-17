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

LOS_PREFIX="lineage"
LOS_VERSION="16.0"
LINARO_VERSION_SHORT="gcc-10.2.0"
LINARO_VERSION="$LINARO_VERSION_SHORT-cortex-a9-neon"
WORK_DIRECTORY="$HOME/android/n51x0-los-$LOS_VERSION"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
REPO_SYNC_THREADS=$(nproc --all)
LOS_REVISION="$LOS_PREFIX-$LOS_VERSION"
GITHUB_REPO="fidoedidoe"
MANIFEST_REPO="android_local_manifests_gt-n51x0"
MANIFEST_BRANCH="$LOS_PREFIX-$LOS_VERSION"
REPO_INIT_FLAGS="--depth=1 --no-clone-bundle"
REPO_SYNC_FLAGS="--quiet --force-sync --no-tags --no-clone-bundle --no-repo-verify"
CLONE_FLAGS="--depth 1"
SLEEP_DURATION="1"
CCACHE="/usr/bin/ccache"
# KERNEL_CROSS_COMPILE=""$WORK_DIRECTORY"/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-linux-androideabi-"
KERNEL_CROSS_COMPILE=""$WORK_DIRECTORY"/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"
NOW=$(date +"%Y%m%d")
TIME="/usr/bin/time -f"
TIME_FORMAT="------------\n The command '%C'\n Completed in [hours:]minutes:seconds \n %E \n------------"
TWRP_VERSION="3.4.0"
COLOUR_RED="\033[0;31m"
COLOUR_GREEN="\033[1;32m"
COLOUR_YELLOW='\033[1;33m'
COLOUR_NEUTRAL="\033[0m"
SKIP_BUILD_STEPS="N"

#############
# Function(s)
#############

unsupported_response () {
  echo -e "${COLOUR_RED}### Response: '$1' was entered, aborting script execution!${COLOUR_NEUTRAL}"
  exit 1
}

#####################
# Main body of script
#####################
echo -e "${COLOUR_YELLOW}###"
echo -e "### Start of build script${COLOUR_NEUTRAL}" 

if [[ -n "$1" ]]; then
  DEVICE_NAME="${1^^}"
  if [[ "$DEVICE_NAME" =~ ^(N5100|N5110|N5120)$ ]]; then
     echo -e "${COLOUR_YELLOW}###${COLOUR_NEUTRAL}"
  else
     echo -e "${COLOUR_RED}###"
     echo "### The passed parameter $DEVICE_NAME is not supported"
     echo -e "###${COLOUR_NEUTRAL}"
     exit
  fi
else
  DEVICE_NAME="N5110"
  echo -e "${COLOUR_YELLOW}###"
  echo "### No passed parameter $DEVICE_NAME assummed"
  echo -e "###${COLOUR_NEUTRAL}"
fi

VANITY_DEVICE_TAG="Samsung Galaxy Note 8.0 (GT-$DEVICE_NAME)"
DEVICE_NAME="${DEVICE_NAME,,}"

echo -e "${COLOUR_YELLOW}### Building for: $VANITY_DEVICE_TAG" 
echo -e "###${COLOUR_NEUTRAL}"

PROMPT=""
echo -e "${COLOUR_YELLOW}### (1/8) Which build type (ROM, Recovery, Kernel? "
echo "###       #1. Full LineageOS $LOS_VERSION Build"
echo "###       #2. TWRP Recovery Only"
echo -e "###       #3. LineageOS Kernel Only${COLOUR_NEUTRAL}"
read -r -p $"### Enter build choice <1/2/3>? `echo $'\n> '`(automatically continues unprompted after 15 seconds):" -t 15 -e -i 1 PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="1"
fi

if [[ "$PROMPT" =~ ^(1|2|3)$ ]]; then
  case "$PROMPT" in
   "1") echo -e "${COLOUR_YELLOW}### Selected: Full LineageOS ROM build... ${COLOUR_NEUTRAL}"
        BUILD_TYPE="full";;
   "2") echo -e "${COLOUR_YELLOW}### Selected: TWRP Recovery Build... ${COLOUR_NEUTRAL}"
        BUILD_TYPE="recovery";;
   "3") echo -e "${COLOUR_YELLOW}### Selected LineageOS Kernel Build... ${COLOUR_NEUTRAL}"
        BUILD_TYPE="kernel";;    
  esac	  
else
  unsupported_response "$PROMPT"
fi

PROMPT=""
read -r -p "### (2/8) Do you want to skip step: #3 (repo init), #4 (repo sync) & #6 (patch)? <Y/n>? `echo $'\n> '`Only select 'Y' if your running back to back builds for the same device`echo $'\n> '`(automatically continues unprompted after 5 seconds): " -t 5 -e -i Y PROMPT
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
  read -r -p "### (3/8) Initialise/Re-base LOS Repo's <Y/n>? `echo $'\n> '`(automatically continues unprompted after 1 seconds): " -t 1 -e -i Y PROMPT
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
    echo -e "${COLOUR_YELLOW}### initialising LOS repo/manifests for first time... ${COLOUR_NEUTRAL}"
    $TIME "$TIME_FORMAT" repo init -u https://github.com/LineageOS/android.git -b $LOS_REVISION $REPO_INIT_FLAGS
  else
    echo -e "${COLOUR_YELLOW}### LOS repo/manifests exists..."
    echo -e "### Reverting all local LOS modifications... ${COLOUR_NEUTRAL}"
    $TIME "$TIME_FORMAT" repo forall -vc "git reset --hard ; git clean -fdx" --quiet
    echo -e "${COLOUR_YELLOW}### All local modifications reverted, local source now aligned to upstream repo!${COLOUR_NEUTRAL}"
  fi
else
  echo -e "${COLOUR_YELLOW}### Skipping Step #3 (repo init), based on earlier input.${COLOUR_NEUTRAL}"
fi

if [[ $SKIP_BUILD_STEPS = "N" ]]; then
  PROMPT=""
  read -r -p "### (4/8) Initialise local_manifest and perform repo sync (initial repo sync sync will take an age) <Y/n>? `echo $'\n> '`(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
  echo
  if [ -z "$PROMPT" ]; then
    PROMPT="Y"
  fi
  if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
    unsupported_response "$PROMPT"
  fi

  if [ ! -d "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY" ]; then
    echo -e "${COLOUR_YELLOW}### create 'local_manifest' and re-run repo sync... ${COLOUR_NEUTRAL}"
    mkdir -p "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY"
    $TIME "$TIME_FORMAT" git clone $CLONE_FLAGS https://github.com/$GITHUB_REPO/$MANIFEST_REPO -b "$MANIFEST_BRANCH" .repo/local_manifests
  else
    echo -e "${COLOUR_YELLOW}### $LOCAL_MANIFESTS_DIRECTORY already exists, skipping git clone${COLOUR_NEUTRAL}"
  fi

  echo -e "${COLOUR_YELLOW}### sync repo with $REPO_SYNC_THREADS threads... ${COLOUR_NEUTRAL}"
  $TIME "$TIME_FORMAT" repo sync --jobs=$REPO_SYNC_THREADS $REPO_SYNC_FLAGS
  echo -e "${COLOUR_YELLOW}### sync complete!${COLOUR_NEUTRAL}"
else
  echo -e "${COLOUR_YELLOW}### Skipping Step #4 (repo sync), based on earlier input.${COLOUR_NEUTRAL}"
fi

if [[ $SKIP_BUILD_STEPS = "N" ]]; then
  PROMPT=""
  read -r -p "### (5/8) Apply patche(s) for device specific setup<Y/n>? `echo $'\n> '`(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
  echo
  if [ -z "$PROMPT" ]; then
    PROMPT="Y"
  fi
  if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
    unsupported_response "$PROMPT"
  fi

  cd "$WORK_DIRECTORY"/device/samsung/$DEVICE_NAME || exit
  if [ ! -f lineage_$DEVICE_NAME.mk ]; then
     echo -e "${COLOUR_YELLOW}### LineageOS 16.0 needs file named 'lineage_$DEVICE_NAME.mk' to build...renaming 'full_$DEVICE_NAME.mk'... ${COLOUR_NEUTRAL}"
     if [ -f full_$DEVICE_NAME.mk ]; then
        mv full_$DEVICE_NAME.mk lineage_$DEVICE_NAME.mk
     else
        echo -e "${COLOUR_RED}### Fatal: cannot find file named 'full_$DEVICE_NAME.mk'... ${COLOUR_NEUTRAL}"
        exit
     fi
  else
     echo -e "${COLOUR_YELLOW}### Found 'lineage_$DEVICE_NAME.mk' nothing to do!${COLOUR_NEUTRAL}"

  fi

  cd "$WORK_DIRECTORY"/device/samsung/$DEVICE_NAME || exit
  echo -e "${COLOUR_YELLOW}### applying $LOCAL_MANIFESTS_DIRECTORY/0002_device_samsung_${DEVICE_NAME}_AndroidProducts.patch${COLOUR_NEUTRAL}"
  patch -p 1 < ../../../$LOCAL_MANIFESTS_DIRECTORY/0002_device_samsung_${DEVICE_NAME}_AndroidProducts.patch
  sleep $SLEEP_DURATION
else
  echo -e "${COLOUR_YELLOW}### Skipping Step #6 (patch), based on earlier input.${COLOUR_NEUTRAL}"
fi


PROMPT=""
read -r -p "### (6/8) Prepare device specific code for: $VANITY_DEVICE_TAG <Y/n>? `echo $'\n> '`(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
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

   cd "$WORK_DIRECTORY" || exit

   #echo -e "${COLOUR_YELLOW}### set environment var to stop issues with prebuilts/misc/.../flex${COLOUR_NEUTRAL}"
   export LC_ALL=C

   echo -e "${COLOUR_YELLOW}### preparing device specific code... ${COLOUR_NEUTRAL}"
   source build/envsetup.sh

   #During recovery build (TWRP) i started hitting SEPolicy issues
   #relating to permissive kernel & building with user, switching to userdebug mitigated this.  
   case "$BUILD_TYPE" in
      "recovery") breakfast lineage_$DEVICE_NAME-userdebug;;
      *) breakfast lineage_$DEVICE_NAME-user;;
   esac

   echo -e "${COLOUR_YELLOW}### running croot... ${COLOUR_NEUTRAL}"
   croot

   echo -e "${COLOUR_YELLOW}### clearing old build output (if any exists)${COLOUR_NEUTRAL}"           
   mka clobber
   echo -e "${COLOUR_YELLOW}### Device specific code prepared!${COLOUR_NEUTRAL}"
else
   echo -e "${COLOUR_YELLOW}### Building kernel, nothing to do here!${COLOUR_NEUTRAL}"           
fi

cd "$WORK_DIRECTORY" || exit

if [[ $SKIP_BUILD_STEPS = "N" ]]; then
  PROMPT=""
  read -r -p "### (6/7) Apply patche(s) <Y/n>? `echo $'\n> '`(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
  echo
  if [ -z "$PROMPT" ]; then
    PROMPT="Y"
  fi
  if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
    unsupported_response "$PROMPT"
  fi

  cd "$WORK_DIRECTORY"/device/samsung/$DEVICE_NAME || exit
  if [ ! -f lineage_$DEVICE_NAME.mk ]; then
     echo -e "${COLOUR_YELLOW}### LineageOS 16.0 needs file named 'lineage_$DEVICE_NAME.mk' to build...renaming 'full_$DEVICE_NAME.mk'... ${COLOUR_NEUTRAL}"
     if [ -f full_$DEVICE_NAME.mk ]; then
        mv full_$DEVICE_NAME.mk lineage_$DEVICE_NAME.mk
     else
        echo -e "${COLOUR_RED}### Fatal: cannot find file named 'full_$DEVICE_NAME.mk'... ${COLOUR_NEUTRAL}"
        exit
     fi
  fi

  cd "$WORK_DIRECTORY"/device/samsung/$DEVICE_NAME || exit
  echo -e "${COLOUR_YELLOW}### applying $LOCAL_MANIFESTS_DIRECTORY/0002_device_samsung_$DEVICE_NAME_AndroidProducts.patch${COLOUR_NEUTRAL}"
  patch -p 1 < ../../$LOCAL_MANIFESTS_DIRECTORY/0002_device_samsung_$DEVICE_NAME_AndroidProducts.patch
  sleep $SLEEP_DURATION
else
  echo -e "${COLOUR_YELLOW}### Skipping Step #6 (patch), based on earlier input.${COLOUR_NEUTRAL}"
fi

#if [[ $SKIP_BUILD_STEPS = "N" ]]; then
#  PROMPT=""
#  read -r -p "### (7/8) Apply patche(s) <Y/n>? `echo $'\n> '`(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
#  echo
#  if [ -z "$PROMPT" ]; then
#    PROMPT="Y"
#  fi
#  if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
#    unsupported_response "$PROMPT"
#  fi
#  cd "$WORK_DIRECTORY"/frameworks/base || exit
#  echo -e "${COLOUR_YELLOW}### applying patch device/samsung/n5100/patch/note-8-nougat-mtp-crash.patch${COLOUR_NEUTRAL}"
#  patch -p 1 < ../../device/samsung/n5100/patch/note-8-nougat-mtp-crash.patch
#  sleep $SLEEP_DURATION
#
#  cd "$WORK_DIRECTORY"/external/wpa_supplicant_8/wpa_supplicant || exit
#  echo -e "${COLOUR_YELLOW}### applying $LOCAL_MANIFESTS_DIRECTORY/0001_external_wpa-supplicant-8_wpa-supplicant_wpa-supplicant-template.patch${COLOUR_NEUTRAL}"
#  patch -p 1 < ../../../$LOCAL_MANIFESTS_DIRECTORY/0001_external_wpa-supplicant-8_wpa-supplicant_wpa-supplicant-template.patch
#  sleep $SLEEP_DURATION
#
#  cd "$WORK_DIRECTORY"/build/core || exit
#  echo -e "${COLOUR_YELLOW}### applying $LOCAL_MANIFESTS_DIRECTORY/0005-build-core-Makefile.patch${COLOUR_NEUTRAL}"
#  patch -p 1 < ../../$LOCAL_MANIFESTS_DIRECTORY/0005-build-core-Makefile.patch
#  sleep $SLEEP_DURATION
#
#  case "$BUILD_TYPE" in
#    "full") cd "$WORK_DIRECTORY" || exit
#            echo -e "${COLOUR_YELLOW}### applying $LOCAL_MANIFESTS_DIRECTORY/0002-custom-toolchain-optimisation.patch${COLOUR_NEUTRAL}"
#            patch -p 1 < $LOCAL_MANIFESTS_DIRECTORY/0002-custom-toolchain-optimisation.patch;;
#    "kernel") 
#            if [[ $DEVICE_NAME = "n5100" ]]; then
#               cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3 || exit
#               echo -e "${COLOUR_YELLOW}### applying $LOCAL_MANIFESTS_DIRECTORY/0003-AnyKernel3-N5100-Device-Names.patch${COLOUR_NEUTRAL}"
#               patch -p 1 < ../../../../$LOCAL_MANIFESTS_DIRECTORY/0003-AnyKernel3-N5100-Device-Names.patch
#               sleep $SLEEP_DURATION
#            fi
#            if [[ $DEVICE_NAME = "n5120" ]]; then
#               cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3 || exit
#               sleep $SLEEP_DURATION
#               echo -e "${COLOUR_YELLOW}### applying $LOCAL_MANIFESTS_DIRECTORY/0004-AnyKernel3-N5120-Device-Names.patch${COLOUR_NEUTRAL}"
#               patch -p 1 < ../../../../$LOCAL_MANIFESTS_DIRECTORY/0004-AnyKernel3-N5120-Device-Names.patch
#               sleep $SLEEP_DURATION
#            fi;;
#  esac
#
#  cd "$WORK_DIRECTORY" || exit
#  echo -e "${COLOUR_YELLOW}### Patches applied!${COLOUR_NEUTRAL}"
#else
#  echo -e "${COLOUR_YELLOW}### Skipping Step #6 (patch), based on earlier input.${COLOUR_NEUTRAL}"
#fi

PROMPT=""
read -r -p "### (8/8) Start $VANITY_DEVICE_TAG build process (this step can take some time depending on CC_CACHE) <Y/n>? `echo $'\n> '`(automatically continues unprompted after 2 seconds): " -t 2 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ $PROMPT =~ ^[Yy]$ ]]; then
   PROMPT=""
   case "$BUILD_TYPE" in
    "full")     echo -e "${COLOUR_YELLOW}### Starting $BUILD_TYPE build, running 'brunch $DEVICE_NAME'... ${COLOUR_NEUTRAL}"
           
                if [ ! -d ".android-certs" ]; then
                   echo -e "${COLOUR_YELLOW}### Generate the keys used for ROM signing...${COLOUR_NEUTRAL}"
                   subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
                   mkdir .android-certs
                   for x in releasekey platform shared media testkey; do 
                       ./development/tools/make_key .android-certs/$x "$subject";
                   done
                else
                   echo -e "${COLOUR_YELLOW}### Keys used for ROM signing already generated..skipping!${COLOUR_NEUTRAL}"
                fi     
                brunch lineage_$DEVICE_NAME-user
                if [ -f "$WORK_DIRECTORY"/out/target/product/"$DEVICE_NAME"/los-"$LOS_VERSION"-"$NOW"-UNOFFICIAL-"$DEVICE_NAME".zip ]; then
                   echo -e "${COLOUR_YELLOW}### Custom ROM flashable zip created at: ${COLOUR_GREEN}$WORK_DIRECTORY"/out/target/product/"$DEVICE_NAME/"
                   echo -e "${COLOUR_YELLOW}### Custom ROM flashable zip name: ${COLOUR_GREEN}los-$LOS_VERSION-$NOW-UNOFFICIAL-$DEVICE_NAME.zip"
                else
		   echo -e "${COLOUR_RED}###"
		   echo "### Custom ROM Compile failure"
                   echo "### (script cannot find the file 'los-$LOS_VERSION-$NOW-UNOFFICIAL-$DEVICE_NAME.zip')!!"
                   echo "### Script aborting."
		   echo -e "###${COLOUR_NEUTRAL}"
		   exit
                fi;;

    "recovery") echo -e "${COLOUR_YELLOW}### Starting $BUILD_TYPE build, running 'mka recoveryimage'... ${COLOUR_NEUTRAL}"
                export WITH_TWRP="true"
                mka recoveryimage
                cd "$WORK_DIRECTORY"/out/target/product/"$DEVICE_NAME"/ || exit 
                if [ -f recovery.img ]; then
                   mv recovery.img twrp-"$TWRP_VERSION"-"$DEVICE_NAME"-"$NOW".img
                   echo -e "${COLOUR_YELLOW}### TWRP flashable image created at: ${COLOUR_GREEN}$WORK_DIRECTORY"/out/target/product/"$DEVICE_NAME/"
                   echo -e "${COLOUR_YELLOW}### TWRP flashable image name: ${COLOUR_GREEN}twrp-$TWRP_VERSION-$DEVICE_NAME-$NOW.img${COLOUR_NEUTRAL}"
                else
		   echo -e "${COLOUR_RED}###"
		   echo "### TWRP Compile failure (script cannot find the file 'recovery.img')!! Script aborting."
		   echo -e "###${COLOUR_NEUTRAL}"
		   exit
                fi;;

    "kernel")   echo -e "${COLOUR_YELLOW}### Starting $BUILD_TYPE build... ${COLOUR_NEUTRAL}"
                export CROSS_COMPILE="$CCACHE $KERNEL_CROSS_COMPILE"
		export ARCH=arm
		export SUBARCH=arm
                export LOCALVERSION="-$DEVICE_NAME-$LINARO_VERSION_SHORT"
                export KBUILD_BUILD_USER="fidoedidoe"
                export KBUILD_BUILD_HOST="on-an-underpowered-laptop"
                cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/ || exit
                mkdir -p "$WORK_DIRECTORY"/out
                echo -e "${COLOUR_YELLOW}CROSS_COMPILE: $CROSS_COMPILE"
                echo -e "defconfig: lineageos_"$DEVICE_NAME"_defconfig${COLOUR_NEUTRAL}"
	        make O="$WORK_DIRECTORY"/out clean
                make O="$WORK_DIRECTORY"/out mrproper
                make O="$WORK_DIRECTORY"/out lineageos_"$DEVICE_NAME"_defconfig
                $TIME "$TIME_FORMAT" make O="$WORK_DIRECTORY"/out -j"$REPO_SYNC_THREADS"
                if [ -f "$WORK_DIRECTORY"/out/arch/arm/boot/zImage ]; then
                   cp "$WORK_DIRECTORY"/out/arch/arm/boot/zImage "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3
                   echo -e "${COLOUR_YELLOW}### building flashable anykernel3 zip file.... ${COLOUR_NEUTRAL}"
                   cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/anyKernel3 || exit
                   zip -r9 kernel.zip * -x .git README.md *placeholder kernel.zip
                   rm zImage
                   mv kernel.zip "$WORK_DIRECTORY"/out/arch/arm/boot/
                   cd "$WORK_DIRECTORY"/out/arch/arm/boot/ || exit
                   mv kernel.zip "$DEVICE_NAME"-kernel-los-"$LOS_VERSION"-"$LINARO_VERSION"."$NOW".zip
                   echo -e "${COLOUR_YELLOW}### flashable kernel zip created at: ${COLOUR_GREEN}$WORK_DIRECTORY/out/arch/arm/boot/"
                   echo -e "${COLOUR_YELLOW}### flashable kernel zip named: ${COLOUR_GREEN}"$DEVICE_NAME"-kernel-los"$LOS_VERSION"-"$LINARO_VERSION"."$NOW".zip${COLOUR_NEUTRAL}"
               else
		   echo -e "${COLOUR_RED}###"
		   echo "### Kernel Compile failure (script cannot find file 'zImage')!! Script aborting."
		   echo -e "###${COLOUR_NEUTRAL}"
		   exit
               fi;;
   esac
else
   unsupported_response "$PROMPT"
fi

echo -e "${COLOUR_YELLOW}### End of Build Script for $VANITY_DEVICE_TAG! ###${COLOUR_NEUTRAL}"
