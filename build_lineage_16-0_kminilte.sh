#!/bin/bash  

VANITY_DEVICE_TAG="S5 Mini (kminilte)"
WORK_DIRECTORY="$HOME/android/kminilte-los-16.0"
REPO_DIRECTORY='.repo'
LOCAL_MANIFESTS_FILE='kminilte.xml'
LOCAL_MANIFESTS_DIRECTORY="$REPO_DIRECTORY/local_manifests"
REPO_SYNC_THREADS=$(nproc --all)
LOS_REVISION="lineage-16.0"
#GITHUB_REPO="SpookCity"
GITHUB_REPO="fidoedidoe"
MANIFEST_BRANCH="P"
REPO_INIT_FLAGS="--depth=1 --no-clone-bundle"
REPO_SYNC_FLAGS="--quiet --force-sync --no-tags --no-clone-bundle"
#REPO_SYNC_FLAGS="--quiet --force-sync --force-broken --no-tags --no-clone-bundle"
SKIP_KERNEL_OPTIMISATIONS="False"

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
  git clone https://github.com/$GITHUB_REPO/android_.repo_local_manifests -b $MANIFEST_BRANCH .repo/local_manifests
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


if [[ $SKIP_KERNEL_OPTIMISATIONS = "False" ]]; then	
  PROMPT=""
  read -r -p "### (5/6) Apply kernel optimisations (cherry-pick from SpookCity P_custom kernel optimisations)  <Y/n>? (automatically continues unprompted after 10 seconds): " -t 10 -e -i Y PROMPT
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

  #echo "### apply cpufreq patch provided by PanzerKnakker this initialises the file to prevent merge conflicts when cherry picking, see: https://forum.xda-developers.com/showpost.php?p=79571283&postcount=325"
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

  echo "### cherry-pick 012 - mm: reduce vm_swappiness"
  git cherry-pick a611985640fe64b9b4189623493e0e5dc4a187ff

  # The following aligns build to P_Custom branch (cherry picked from N_Custom branch). At the time of writing, P_custom doesn't compile when used within local manifests (suspected issue with toolchain)
  # I'm to stupid to make git cherry pick from P_custom branch (bad object errors), all picks beloew are taken directly from N_custom branch (as they are identicle). However, this does cause some issues
  # as i cannot cherry pick some P_Custom branch modifications. see individual cherry-picks for details.  

  echo "### cherry-pick 101 - arm: add SDIV/UDIV emulation for ARMv7 processors"
  git cherry-pick 7beafdb23af0a8fc79a04e8d2087fd954dae06df

  echo "### cherry-pick 102 - Optimized-ARM-RWSEM-algorithm"
  git cherry-pick 38c2a01b0850afa93ca855dd040c9af23b917442

  echo "### cherry-pick 103 - cpufreq-ondemand-Set-MIN_LATENCY_MULTIPLIER-to-20"
  git cherry-pick 5fcffee4586b3607c187ee79af038db628c321c1

  echo "### cherry-pick 104 - mutex-Make-more-scalable-by-doing-less-atomic-operations"
  git cherry-pick 9ae1fdcd143ec4ef97f73fae77014c477a396f0c

  echo "### cherry-pick 105 - mutex-Queue-mutex-spinners-with-MCS-lock-to-reduce-cc"
  git cherry-pick b671997276f329e342e892077dcd2ad1535491aa

  echo "### cherry-pick 106 - hrtimer-Consider-preemption-when-migrating-hrtimer-cpu"
  git cherry-pick 0e634f75b244fbc35c09ba21881ba2c602aef1ec

  echo "### cherry-pick 107 - sched-Use-cached-value-of-span-instead-of-calling-sds"
  git cherry-pick e7449ad002371509ae618720e6f3f8943b238f28

  echo "### cherry-pick 108 - sched-scale-cpu-load-for-judgment-of-group-imbalance"
  git cherry-pick f30c95f8b8a0813926e563809198cc3494c3bd5e

  echo "### cherry-pick 109 - writeback-fix-occasional-slow-sync"
  git cherry-pick 0fd1fe4407e11e33413cd3a4c863f20f013df710

  echo "### cherry-pick 110 - writeback-fix-writeback-cache-thrashing"
  git cherry-pick deb1a22e9940777c13a6ad5d2128e7e7798d54f4

  echo "### cherry-pick 111 - writeback-increase-bdi_min_ratio-to-5"
  git cherry-pick e14b04520d9b38cb527a126f60102fc1e0c6b6e0

  echo "### cherry-pick 112 - sched-Implement-smarter-wake-affine-logic"
  git cherry-pick a2c26b806bca59b3fffebe53fdab36ef40a11c67

  echo "### cherry-pick 113 - sched-Micro-optimize-the-smart-wake-affine-logic"
  git cherry-pick c2becb26aa8f8e780d297cab38b8286f5afa3a18

  echo "### cherry-pick 114 - sched-Fix-clear-NOHZ_BALANCE_KICK"
  git cherry-pick 2615b39b1a976a8e0f2ea4a7de23c3d435eba024

  echo "### cherry-pick 115 - readahead=512kB"
  git cherry-pick 655a8918bb488e88c8d0722444d095aa3ff4c4e3

  echo "### cherry-pick 116 - sched-Fix-select_idle_sibling-bouncing-cow-syndrome"
  git cherry-pick ecd4195e536f0484285dc319a32310e9d5ff3d66

  echo "### cherry-pick 117 - sync-dont-block-the-flusher-thread-waiting-on-IO"
  git cherry-pick 647e23cc44a0bbcc5b67a4735341b49c9da194cd

  echo "### cherry-pick 118 - rwsem-Implement-writer-lock-stealing-for-better-scalabilty"
  git cherry-pick 3ab24484a7d3a7eb7d0d031f454cdcdb25cc3025

  echo "### cherry-pick 119 - rwsem-spinlock-Implement-writer-lock-stealing"
  git cherry-pick 9a8fb72a68e1500f900214a0d6364c89d6e931cd

  echo "### cherry-pick 120 - USB-gadgetOptimize-tx-path-for-better-performance"
  git cherry-pick f80fdbed02732c1b6788646eaae5ec32f80267c0

  echo "### cherry-pick 121 - ARM-mm-implement-LoUIS-API-for-cache-maintenance-ops"
  git cherry-pick 64adc652f226d052181e386121dbac9f27487373

  echo "### cherry-pick 122 - ARM-kernel-update-cpu_disable-to-use-cache-LoUIS-maintenance API"
  git cherry-pick e9e7884e51dc935ee2d54c91d34808fe024d455c

  echo "### cherry-pick 123 - ARM-mm-update-v7_setup-to-the-new-LoUIS-cache-main"
  git cherry-pick db4f876ba2078dfc518dddd98552cc2a5b315323

  echo "### cherry-pick 124 - mutex: use generic atomic_dec-based implementation for ARMv6+"
  git cherry-pick 99d479965dfd79a0a8e190161574cd70d4683040

  echo "### cherry-pick 125 - writeback: fix race that causes writeback hung"
  git cherry-pick 04d0ee26861c2203278ddf47a063377dd5a3a6ef

  echo "### cherry-pick 126 - sched: Reduce overestimating rq->avg_idle"
  git cherry-pick 070833e0519ecd18bab09e50d49decd609d5db01

  echo "### cherry-pick 127 - SCHEDULER: Autogroup by current user android UID instead of task ID"
  git cherry-pick 3a35ea6e16f8fa01d5215137d7575c2d89956caf

  echo "### cherry-pick 128 - Input: Improve the events-per-packet estimate"
  git cherry-pick c3d8072b9c80fc1c11d6122256c6f2e1861b660a

  echo "### cherry-pick 129 - audit:No logging"
  echo "### skipped already applied"
  #git cherry-pick 1a9c354552d6bd7f37444ddd61adc46e2f640c17

  echo "### cherry-pick 130 - Update ARM topology and add cpu_power driver"
  git cherry-pick 8fd91b75104e39d1cf9b874490ffcfbba047e760

  echo "### cherry-pick 131 - 1.6ghz OC and initial voltage stuffs"
  echo "### skipped already applied"
  #git cherry-pick a20c1790de4d5152d986ca52563f20769c14ab69

  echo "### cherry-pick 132 - voltage table access"
  echo "### skipped already applied"
  #git cherry-pick 81d88aae7262d17a4538440d783dbc3ed80ffcc1

  echo "### cherry-pick 133 - GPU OC to 533mhz"
  echo "### skipped already applied"
  #git cherry-pick 505dd3782eb63b56113dd2c1095e981c90c7d9fc

  echo "### cherry-pick 134 - GPU OC to 600mhz"
  echo "### skipped already applied"
  #git cherry-pick 548b71b9417b3e9628b71e2e2f6dc93494a4d886

  echo "### cherry-pick 135 - usb: gadget: mass_storage: add sysfs entry for cdrom to LUNs {DriveDr...old}"
  git cherry-pick d853747db78ea0a51be46eafa9323d834d9e2462

  echo "### cherry-pick 136 - block: disable add_random"
  git cherry-pick 88c8150bc70cb2f185fbed7c2cf7546c63731f98

  echo "### cherry-pick 137 - tcp: tweak for speed"
  git cherry-pick 5abcd313a3bafc02851d0981ae71d7a6401124aa

  echo "### cherry-pick 138 - CPU voltage control"
  echo "### skipped already applied"
  #git cherry-pick ac265ac6e7ea1905abef0b8bfdd1c6996004b08f

  echo "### cherry-pick 139 - lib/int_sqrt.c: optimize square root algorithm"
  echo "### skipped already applied"
  #git cherry-pick dd91ace39766f6f3e92bd4b37c88d4f18d3a1435

  echo "### cherry-pick 140 - af_unix: speedup /proc/net/unix"
  echo "### skipped already applied"
  #git cherry-pick bd7b120e643d9ff129c430fc262a6688d6849e6b

  echo "### cherry-pick 141 - lower ARM_MAX_VOLT"
  echo "### skipped already applied"
  #git cherry-pick 1ccd52491ed93f63ab8082bdfae193ac41633df9

  echo "### cherry-pick 142 - wireless - bcmdhd - reduce scan dwell time to reduce power usage"
  git cherry-pick 35641b2853ba6aa65755816391e35c2bc7051935

  echo "### cherry-pick 143 - bcmdhd reduce wakelocks"
  git cherry-pick cdb7d82f0ac12009f25fba5192a5fd73b9309c8e

  echo "### cherry-pick 144 - Fix CONFIG_HZ dependency in wifi driver."
  git cherry-pick fca9baf32f290004c2c38d5ae33070a667995c1e

  echo "### cherry-pick 145 - usb-gadget: support USB keyboard"
  git cherry-pick 7902b2a618bdad7349c8304b0523b74fc47a3e35

  echo "### cherry-pick 146 - GPU optimization flags"
  echo "### skipped already applied"
  #git cherry-pick d774f273b1aa3d54943d6b814e9b4331eacf2ec0

  echo "### cherry-pick 147 - readahead: make context readahead more conservative"
  git cherry-pick de1f6d4c8db21081e3c9ca03f2f222f364ed10d4

  echo "### cherry-pick 148 - block/partitions: optimize memory allocation in check_partition()"
  git cherry-pick 15e00d5b29004a1843bcb9af3b29c00d00f674c1

  echo "### cherry-pick 149 - proc: much faster /proc/vmstat"
  git cherry-pick f131b7bbb5e82401486e479fb15120874428a285

  echo "### cherry-pick 150 - Fix build (not cherry pick available from N_custom, apply new file)"
  cp ~/android/build_scripts/rwsem.h  arch/arm/include/asm/
  git add  arch/arm/include/asm/rwsem.h
  git commit -m "ading wrsem.h to fix build (P_custom hash: 638bd35d52ecbd2195149cd24676ae97006b96cb)"
  #git cherry-pick 638bd35d52ecbd2195149cd24676ae97006b96cb

  echo "### cherry-pick 151 - Add some I/O shedulers and CPU governors"
  echo "### skipped, no N_custon cherry-pick available (P_custom cherry-pick is: 8e5fe368dc1589636a644a0ab3ec6452f43d37ea)"
  #git cherry-pick 8e5fe368dc1589636a644a0ab3ec6452f43d37ea
  echo "### cherry-pick 152 - compiler-gcc: integrate the various compiler-gcc[345].h files"
  git cherry-pick 30956cd551998af2062dc87f507f89f77f0c107a

  echo "### cherry-pick 153 - Add anykernel2"
  echo "### skipped, no N_custon cherry-pick available (P_custom cherry-pick is: b0d0893d2abd03aa3843aa90d5dd3f5aabf30769)"
  #git cherry-pick b0d0893d2abd03aa3843aa90d5dd3f5aabf30769

  echo "### cherry-pick 154 - O3 plus lots of optimization flags"
  echo "### skipped, no N_custon cherry-pick available (P_custom cherry-pick is: 9dca733827504586a6f4b235a52563eb4ef6d35d)"
  #git cherry-pick 9dca733827504586a6f4b235a52563eb4ef6d35d

fi

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
