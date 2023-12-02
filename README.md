# piCoreCDSP
The goal of this project is to provide an easy way to install CamillaDSP 1.0.3 including GUI
and automatic samplerate switching on a [piCorePlayer](https://www.picoreplayer.org/) installation.

## Requirements
- a fresh piCorePlayer 8.2.0 installation without any modifications
- on an armv7 or arch64 compatible device

## How to install
1. Increase piCorePlayer SD Card size to at least 200MB
   - In `Main Page > Additional functions > Resize FS`
   - Select `200 MB` or one of the larger options
2. Run `install_cdsp.sh` on piCorePlayer:
   - SSH onto the piCorePlayer as user `tc`
     - Usually `ssh tc@pcp.local` or `ssh tc@<IP of your piCorePlayer>` with password `piCore`
     - [How to find the IP adress of your piCorePlayer](https://docs.picoreplayer.org/how-to/determine_your_pcp_ip_address/)
   - Run  
     `wget https://github.com/JWahle/piCoreCDSP/raw/main/install_cdsp.sh && chmod u+x install_cdsp.sh && ./install_cdsp.sh`
   - Or if you want to run a modified version of the script, see the [For Developers](#for-developers) section
3. Open CamillaGUI in the browser:
   - It will be running on port 5000 of piCorePlayer.  
     Usually can be opened via [pcp.local:5000](http://pcp.local:5000) or `<IP of your piCorePlayer>:5000`
   - Under `Playback device` enter the settings for your DAC (by default, the Raspi headphone output is used)
     - These HAVE TO BE CORRECT, otherwise CamillaDSP and Squeezelite won't start!
       - `device`: The Alsa device name of the DAC
         - A list of available devices can be found in `Squeezelite settings > Output setting`
         - If you know the `sampleformat` for your DAC or want to find it through trial and error,
           then choose a device with `hw:` prefix. Otherwise, use one with `plughw:` prefix.
       - `channels`: a supported channel count for the DAC  
         Usually 2 for a stereo DAC.
       - `sampleformat`: a supported sample format for the DAC. (Only important, when NOT using a `plughw:` device)
   - Hit `Apply and save`
     - You should see channel meters and `State: RUNNING` on the left
     - If things go wrong, check the CamillaDSP log file via the `Show log file` button for more info

## Troubleshooting

Check, your system meets all the requirements, reboot and try to install again.

Sometimes, the script's dependencies get corrupted while downloading.  
In that case, you'll see messages like this somewhere in the log:  
`Checking MD5 of: openssl.tcz.....FAIL`  
There are a couple of things, you can try to work around this:
1. reboot and try to install again, repeat until successful
2. You can try to switch the extension repo:  
   - Reboot, then go to Main Page > Extensions > wait for the check to complete (until you see 5 green check marks)  
   - Then go to Available > Current repository > select "piCorePlayer mirror repository" and "Set".  
   - Run the script again.

If the error persists, post the error message on the piCoreCDSP Thread on
[diyaudio.com](https://www.diyaudio.com/community/threads/camilladsp-for-picoreplayer.402255/)
or [slimdevices.com](https://forums.slimdevices.com/forum/user-forums/linux-unix/1646681-camilladsp-for-picoreplayer).

## How to uninstall
If you want to uninstall without setting up piCorePlayer again,
reconfigure your audio output device in the pCP UI,
then uninstall the piCoreCDSP Extension
(In `Main Page > Extensions > Installed >` select `piCoreCDSP.tcz`, press `Delete`)
and reboot.
Afterward SSH onto the piCorePlayer and remove the `pcm.camilladsp` entry from `/etc/asound.conf`.
This is easy to do with the Nano text editor:
```shell
tce-load -wil -t /tmp nano
nano /etc/asound.conf
```
Lastly, remove the installation script and CamillaDSP configs + filters and save your changes:
```shell
rm -f /home/tc/install_cdsp.sh
rm -rf /etc/sysconfig/tcedir/camilladsp/
pcp backup
```

## Implementation
The `install_cdsp.sh` script downloads the following projects including dependencies
and installs them with convenient default settings:
- https://github.com/spfenwick/alsa_cdsp.git (forked from https://github.com/scripple/alsa_cdsp)
- https://github.com/HEnquist/camilladsp
- https://github.com/HEnquist/camillagui-backend

## For developers

In this section it is assumed, that your piCorePlayer is available on [pcp.local](http://pcp.local).
If this is not the case, replace occurrences of `pcp.local` with the IP-Adress/hostname of your piCorePlayer.

### Modifying the installation script
If you made some changes to the installation script on your local machine and want to run it quickly on the piCorePlayer,  
run the following command from the location of the script:  
```shell
scp install_cdsp.sh tc@pcp.local:~ && ssh tc@pcp.local "./install_cdsp.sh"
```

### Running your own python scripts
You can run python scripts requiring `pycamilladsp` or `pycamilladsp-plot` like this:
1. Copy your script from your local machine to pCP: `scp <your_script> tc@pcp.local:~`
2. In `Tweaks > User Commands` set one of the commands to this:  
   `sudo -u tc sh -c 'source /usr/local/camillagui/environment/bin/activate; python3 /home/tc/<your_script>'`
3. Save and reboot

If you need to access files in your script, make sure to use absolute paths.
