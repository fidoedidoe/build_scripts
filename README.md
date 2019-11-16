# Overview
Collection of `#!/bin/bash` scripts created to help automate the initial build or subsequent rebuild of AOSP (or variants) from source for a number of devices. Each script follows a similar approach, the instructions below are in general applicable to all. In essence each script automates the steps and processes created by others (none of which is my own work - all credit goes to the orignal creators). 

* build_lineage_16-0_kminilte.sh
* build_lineage_m9.sh
* build_aosp_7-1-0_nexus7.sh
* build_lineage_14-1_gt-n51x0.sh {N5100|N5110|N5120}
* etc

I have only tested these scripts on my own environment: Gnome Ubuntu 19.04; 16GB RAM; i7-7700HQ; If your environment differs from this then your experience may differ from mine. Setting up your build environment is beyond the scope of this readme, there's lots of good advice / examples out there.

##### Thanks
- [spookcity138](https://forum.xda-developers.com/member.php?u=7065337) & [jimmy999x](https://forum.xda-developers.com/member.php?u=7341542). For being open to questions on building for kminilte, taking the time to educate me at each and every tentative step and demonstrating great patience.
- [flyhalf205](https://forum.xda-developers.com/member.php?u=3082717) for advice on building for Lineage 15 on M9.
- [anddisa](https://forum.xda-developers.com/member.php?u=2188693) For being open to questions on building for grouper/tilapia and demonstrating great patience.

## build_slimrom7_kminilte.sh

##### Credits
- [spookcity138](https://forum.xda-developers.com/member.php?u=7065337)
- [jimmy999x](https://forum.xda-developers.com/member.php?u=7341542)
- [anddisa](https://forum.xda-developers.com/member.php?u=2188693)
- [walter79](https://forum.xda-developers.com/member.php?u=382340)

### How to execute the build script

###### Assumptions
- This readme assumes you have a working build environment, the setup is beyond the scope of this guide - you will find plenty well constructed guides out there, one being: [How to Setup Ubuntu 18.04 LTS Bionic Beaver to Compile Android ROMs](https://nathanpfry.com/how-to-setup-ubuntu-18-04-lts-bionic-beaver-to-compile-android-roms/).
- you have a folder structure `~/android/build_scripts`


###### Step 1 - Setup/Configure Compiler Cache (ccache)
Having ccache setup and configured correctly will significantly speed up subsequent compile times. In my environment I've seen compile times drop from ~90 minutes, to ~25 minutes and down to just 5 minutes under certain conditions. Your mileage may vary.

Install ccache (Ubuntu)
````
sudo apt-get install ccache
````
Configure environment variables, by editing `~/.bashrc` and adding the following at the bottom of the script
````
export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache" # Set Compile Cache location
export CCACHE_SIZE="15G" # Set compile cache size (increase as necessary)
export CCACHE_COMPRESS=1 # Save space in compile cache
export CCACHE_EXEC="/usr/bin/ccache"
````
Reload bashrc to incorporate above change
````
source ~/.bashrc
````
The stats for the cache can be seen using `ccache -s`, the stats (such as cache hit success) will improve over time. 


###### Step 2 - configure Jacks Server to use 4GB memory (mitigates OOM Error)

Configure environment variables, by editing `~/.bashrc` and adding the following at the bottom of the script
````
export ANDROID_JACK_VM_ARGS="-Xmx4g -Dfile.encoding=UTF-8 -XX:+TieredCompilation"
````
Reload bashrc to incorporate above change
````
source ~/.bashrc
````

###### Step 3 - Install the build script: 
Ensure the script (named: `build_slimrom7_kminilte.sh`) is located in the following folder
```
~/android/build_scripts
```
Make sure the script has execute permissions
```
chmod ug+x ~/android/build_scripts/build_slimrom7_kminilte.sh
```

###### Step 4 - Validate script variables:
Open the the file and validate the variable defaults such as: `WORK_DIRECTORY; SLIM_REVISION; REPO_SYNC_THREADS, etc etc`, are appropriate for your intended build version and folder structure and hardware/broadband capability, ie: 
```
vi ~/android/build_scripts/build_slimrom7_kminilte.sh

...
SAMPLE_REPO_DIRECTORY='frameworks'
WORK_DIRECTORY="$HOME/android/slimrom7"
REPO_SYNC_THREADS=64
SLIM_REVISION="ng7.1"
LOS_REVISION="cm-14.1"
...
```

###### Step 5 - Execute Script:
Change the the script directory and execute the script:  
```
cd ~/android/build_scripts
./build_slimrom7_kminilte.sh
```
