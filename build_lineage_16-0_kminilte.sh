#!/bin/bash  

VANITY_DEVICE_TAG="S5 Mini (kminilte)"
WORK_DIRECTORY="$HOME/android/kminilte-los-16.0"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_FILE='kminilte.xml'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
#REPO_SYNC_THREADS="4"
REPO_SYNC_THREADS=$(nproc --all)
LOS_REVISION="lineage-16.0"
SPOOK_CITY_REVISION="P"
REPO_INIT_FLAGS="--depth=1 --no-clone-bundle"
#REPO_INIT_FLAGS="--no-clone-bundle"
REPO_SYNC_FLAGS="--quiet --force-sync --no-tags --no-clone-bundle"
#REPO_SYNC_FLAGS="--quiet --force-sync --force-broken --no-tags --no-clone-bundle"

echo "###"
echo "### Start of build script for: $VANITY_DEVICE_TAG" 
echo "###"

PROMPT=""
read -r -p "### (1/6) Initialise LOS Repo and manifest <Y/n>? (automatically continues unprompted after 5 seconds): " -t 5 -e -i Y PROMPT
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
  echo "### step 1/1: reverting all local LOS modifications..."
  repo forall -vc "git reset --hard ; git clean -fdx" --quiet
  echo "### step 1 - 1: complete"
fi


PROMPT=""
read -r -p "### (2/6) Continue with git clone 'local_manifests' and sync repo (initial sync will take an age) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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
  git clone https://github.com/Spookcity/android_.repo_local_manifests -b $SPOOK_CITY_REVISION .repo/local_manifests
else
  echo "### local_manifest exists...skipping."           
fi

echo "### sync repo with $REPO_SYNC_THREADS threads..."
#repo sync -c --quiet --jobs="$REPO_SYNC_THREADS" $REPO_SYNC_FLAGS
repo sync --jobs="$REPO_SYNC_THREADS" $REPO_SYNC_FLAGS

PROMPT=""
read -r -p "### (3/6) Continue and apply device specific patch <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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
read -r -p "### (4/6) Continue and prepare device specific code for: $VANITY_DEVICE_TAG <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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

echo "### clearing old build output (if any exists)"           
mka clobber

cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "### (5/6) Apply kernel optimisations (cherry-pick from SpookCity N_custom kernel optimisations), inspiration and initial patch credited to Panzerknakker)  <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

cd "$WORK_DIRECTORY"/kernel/samsung/kminilte || exit

echo "### to apply the cherry-pick's we need to git fetch the 'N_custom' branch"
git fetch github N_custom

echo "### apply cpufreq patch provided by PanzerKnakker this initialises the file to prevent merge conflicts when cherry picking, see: https://forum.xda-developers.com/showpost.php?p=79571283&postcount=325"
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

echo "### cherry-pick 009 - GPU Optimisations Flags"
git cherry-pick d774f273b1aa3d54943d6b814e9b4331eacf2ec0

echo "### cherry-pick 010 - audit: Make logging opt-in via console_loglevel"
git cherry-pick 429e4d526dc0a4661e376dfe75119aac7d91da97 

echo "### cherry-pick 011 - audit:No logging"
git cherry-pick 1a9c354552d6bd7f37444ddd61adc46e2f640c17 

exho "### cherry-pick 012 - mm: reduce vm_swappiness"
git cherry-pick a611985640fe64b9b4189623493e0e5dc4a187ff

cd "$WORK_DIRECTORY" || exit

PROMPT=""
read -r -p "### (6/6) Continue with $VANITY_DEVICE_TAG ROM build process (this step can take some time depending on CC_CACHE) <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
echo
if [ -z "$PROMPT" ]; then
  PROMPT="Y"
fi
if [[ ! $PROMPT =~ ^[Yy]$ ]]; then
  echo "### Response: '$PROMPT', exiting!"
  exit 1
fi

echo "### running 'mka bacon with $REPO_SYNC_THREADS threads'..."
mka bacon -j$REPO_SYNC_THREADS

echo "### End of Build Script for $VANITY_DEVICE_TAG! ###"
