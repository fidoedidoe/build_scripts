#!/bin/bash  

###
### NOTE:
### 1) you may need to modify the variables below to better suit your personal build environment 
### 2) this build uses a custom toolchain. forked repo: https://github.com/fidoedidoe/gcc-prebuilts
### 


#############
# Variable(s)
#############

DEVICE_NAME="n7100"
VANITY_DEVICE_TAG="Galaxy Note II ($DEVICE_NAME)"
LINARO_VERSION="linaro-7.4.1-cortex-a9-neon"
WORK_DIRECTORY="$HOME/android/n7100-los-16.0"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_FILE='$DEVICE_NAME.xml'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
REPO_SYNC_THREADS=$(nproc --all)
LOS_REVISION="lineage-16.0"
#GITHUB_REPO="ComicoTeam"
GITHUB_REPO="fidoedidoe"
MANIFEST_BRANCH="lineage-16.0"
CLONE_FLAGS="--depth 1"
REPO_INIT_FLAGS="--depth=1 --no-clone-bundle"
REPO_SYNC_FLAGS="--quiet --force-sync --no-tags --no-clone-bundle --no-repo-verify"
#REPO_SYNC_FLAGS="--quiet --force-sync --force-broken --no-tags --no-clone-bundle"
KERNEL_CROSS_COMPILE=""$WORK_DIRECTORY"/prebuilts/gcc/linux-x86/arm/arm-eabi-4.9/bin/arm-linux-androideabi-"
NOW=$(date +"%Y%m%d")

#############
# Function(s)
#############

unsupported_response () {
  echo "### Response: '$1' is not supported, exiting!"
  exit 1
}

#####################
# Main body of script
#####################


echo "###"
echo "### Start of build script for: $VANITY_DEVICE_TAG" 
echo "###"

PROMPT=""
echo "### (1/5) Which build type (ROM, Recovery, Kernel? "
echo "###       #1. Full LineageOS $LOS_VERSION Build"
#echo "###       #2. TWRP Recovery Only"
#echo "###       #3. LineageOS Kernel Only"
read -r -p "### Enter build choice <1/2/3>? (automatically continues unprompted after 5 seconds): " -t 5 -e -i 1 PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="1"
fi

if [[ "$PROMPT" =~ ^(1|3)$ ]]; then
  case "$PROMPT" in
   "1") echo "### Selected: Full LineageOS ROM build..."
        BUILD_TYPE="full";;
   #"2") echo "### Selected: TWRP Recovery Build..."
   #     BUILD_TYPE="recovery";;
   #"3") echo "### Selected LineageOS Kernel Build..."
   #     BUILD_TYPE="kernel";;
  esac
else
  unsupported_response "$PROMPT"
fi


PROMPT=""
read -r -p "### (2/5) Initialise LOS Repo and manifest <Y/n>? (automatically continues unprompted after 5 seconds): " -t 5 -e -i Y PROMPT
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
  echo "### step 1/1: reverting all local LOS modifications..."
  repo forall -vc "git reset --hard ; git clean -fdx" --quiet
  echo "### step 1 - 1: complete"
fi


PROMPT=""
read -r -p "### (3/5) Continue with git clone 'local_manifests' and sync repo (initial sync will take an age) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  unsupported_response "$PROMPT"
fi

if [ ! -d "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY" ]; then
  echo "### create 'local_manifest' and re-run repo sync..."           
  #mkdir -p "$WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY"
  git clone $CLONE_FLAGS https://github.com/$GITHUB_REPO/android_local_manifests_n7100 $WORK_DIRECTORY/$LOCAL_MANIFESTS_DIRECTORY -b $MANIFEST_BRANCH
else
  echo "### local_manifest exists...skipping."           
fi

echo "### sync repo with $REPO_SYNC_THREADS threads..."
repo sync --jobs="$REPO_SYNC_THREADS" $REPO_SYNC_FLAGS

PROMPT=""
read -r -p "### (4/5) Continue and prepare device specific code for: $VANITY_DEVICE_TAG <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  unsupported_response "$PROMPT"
fi

#The following is unecessary for kernel build
if [[ ! $BUILD_TYPE = "kernel" ]]; then

  echo "### prepare device specific code..."
  source build/envsetup.sh
  lunch lineage_n7100-userdebug

  echo "### running croot..."
  croot

  echo "### clearing old build output (if any exists)"           
  mka clobber
fi

cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "### (5/5) Continue with $VANITY_DEVICE_TAG ROM build process (this step can take some time depending on CC_CACHE) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  unsupported_response "$PROMPT"
fi


if [[ $PROMPT =~ ^[Yy]$ ]]; then
   PROMPT=""
   case "$BUILD_TYPE" in
    "full")     echo "#### Generate the keys used for ROM signing..."
                subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
                rm -rf .android-certs
                mkdir -p .android-certs
                for x in releasekey platform shared media testkey
                do
                    echo -en "\n" | ./development/tools/make_key .android-certs/$x "$subject"
                done
                echo "### Starting $BUILD_TYPE build, running 'mka bacon -j$REPO_SYNC_THREADS'..."
                mka bacon -j$REPO_SYNC_THREADS;;

    #"recovery") echo "### Starting $BUILD_TYPE build, running 'mka recoveryimage'..."
    #            export WITH_TWRP="true"
    #            mka recoveryimage
    #            cd "$WORK_DIRECTORY"/out/target/product/n7100/ || exit
    #            mv recovery.img twrp-"$DEVICE_NAME"-"$NOW".img
    #            echo "### TWRP flashable image name: twrp-$DEVICE_NAME-$NOW.img";;

    "kernel")   echo "### Starting $BUILD_TYPE build..."
                export CROSS_COMPILE="$KERNEL_CROSS_COMPILE"
                export ARCH=arm
                export SUBARCH=arm
                cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/ || exit
                mkdir -p "$WORK_DIRECTORY"/out
                #if building between lineage and kernel only, sometimes residue files are left. 
                rm -rf "$WORK_DIRECTORY"/out/*
                make O="$WORK_DIRECTORY"/out clean
                make O="$WORK_DIRECTORY"/out mrproper
                make O="$WORK_DIRECTORY"/out lineageos_n7100_defconfig
                make O="$WORK_DIRECTORY"/out -j"$REPO_SYNC_THREADS"
                #cp "$WORK_DIRECTORY"/out/arch/arm/boot/zImage "$WORK_DIRECTORY"/kernel/samsung/smdk4412/AnyKernel2 || exit
                #echo "### building flashable anykernel2 zip file...."
                #cd "$WORK_DIRECTORY"/kernel/samsung/smdk4412/AnyKernel2 || exit
                #zip -r9 kernel.zip * -x .git README.md *placeholder kernel.zip
                #rm zImage
                #mv kernel.zip "$WORK_DIRECTORY"/out/arch/arm/boot/
                #cd "$WORK_DIRECTORY"/out/arch/arm/boot/ || exit
                #mv kernel.zip "$LOS_REVISION"-"$DEVICE_NAME"-kernel-"$LINARO_VERSION"."$NOW".zip
                #echo "### flashable zip created at: $WORK_DIRECTORY/out/arch/arm/boot/"
                #echo "### flashable zip named: $LOS_REVISION-$DEVICE_NAME-kernel-"$LINARO_VERSION".$NOW.zip";;
   esac
else
   unsupported_response "$PROMPT"
fi


echo "### End of Build Script for $VANITY_DEVICE_TAG! ###"
