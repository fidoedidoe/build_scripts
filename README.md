# Overview
Collection of `#!/bin/bash` scripts created to help automate the initial build or subsequent rebuild of AOSP (or variants)  from source for a number of devices. Each script follows a similar approach, the instructions below are in general applicable to to each. In essence it automates the steps and processes created by others (none of which is my own work - all credit goes to the original creators). I have only tested this script on my own working environment: Gnome Ubuntu 17.04; 16GB RAM; i7-7700HQ; If your environment differs from this then your experience may differ from mine.   

* build_slimrom7_kminilte.sh
* build_lineage_m9.sh 
* etc

##### Thanks
- [spookcity138](https://forum.xda-developers.com/member.php?u=7065337) & [jimmy999x](https://forum.xda-developers.com/member.php?u=7341542). For being open to questions on building for kminilte, taking the time to educate me at each and every tentative step and demonstrating great patience.
- [flyhalf205](https://forum.xda-developers.com/member.php?u=3082717) for advice on building for Lineage 15 on M9. 

## build_slimrom7_kminilte.sh

##### Credits
- [spookcity138](https://forum.xda-developers.com/member.php?u=7065337)
- [jimmy999x](https://forum.xda-developers.com/member.php?u=7341542)

### How to execute the build script

###### Assumptions
- This readme assumes you have a working build environment, the setup is beyond the scope of this guide - you will find plenty well constructed guides out there, one being: [How to Setup Ubuntu 16.04 LTS Xenial Xerus for Compiling Android ROMs](https://forum.xda-developers.com/chef-central/android/guide-how-to-setup-ubuntu-16-04-lts-t3363669).
- you have a folder structure `~/android/build_scripts`


###### Step 1 - Install the script: 
Ensure the script (named: `build_slimrom7_kminilte.sh`) is located in the following folder
```
~/android/build_scripts
```
Make sure the script has execute permissions
```
chmod ug+x ~/android/build_scripts/build_slimrom7_kminilte.sh
```


###### Step 2 - Validate script variables:
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

###### Step 3 - Execute Script:
Change the the script directory and execute the script:  
```
cd ~/android/build_scripts
./build_slimrom7_kminilte.sh.sh
```
