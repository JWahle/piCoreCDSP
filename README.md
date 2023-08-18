# piCoreCDSP
The goal of this project is to provide an easy way to install CamillaDSP 1.0.3 including GUI and automatic samplerate switching on a piCorePlayer installation.

## Requirements
- a fresh piCorePlayer 8.2.0 installation without any modifications
- on an armv7 or arch64 compatible device

## How to install
1. Increase piCorePlayer SD Card size to at least 200MB
   - In `Main Page > Additional functions > Resize FS`
   - Select `200 MB` or one of the larger options
2. Run `install_cdsp.sh` on piCorePlayer:
   - SSH onto the piCorePlayer
     - Usually `ssh tc@pcp.local` or `ssh tc@<IP of your piCorePlayer>` with password `piCore`
     - [How to find the IP adress of your piCorePlayer](https://docs.picoreplayer.org/how-to/determine_your_pcp_ip_address/) 
   - Run  
     `wget https://github.com/JWahle/piCoreCDSP/raw/main/install_cdsp.sh && chmod u+x install_cdsp.sh && ./install_cdsp.sh`
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
The `install_cdsp.sh` script downloads the following projects including dependencies and installs them with convenient default settings:
- https://github.com/scripple/alsa_cdsp
- https://github.com/HEnquist/camilladsp
- https://github.com/HEnquist/camillagui-backend

## For developers
If you made some changes to the script and want to run it quickly on the piCorePlayer, run  
`scp install_cdsp.sh tc@pcp.local:~ && ssh tc@pcp.local "./install_cdsp.sh"`  
If your piCorePlayer is not available on [pcp.local](http://pcp.local),
replace both occurrences of `pcp.local` with the IP-Adress of your piCorePlayer.

## Troubleshooting

Check, your system meets all the requirements, reboot and try to install again.  
If the error persists, post the error message on the piCoreCDSP Thread on [diyaudio.com](https://www.diyaudio.com/community/threads/camilladsp-for-picoreplayer.402255/) or [slimdevices.com](https://forums.slimdevices.com/forum/user-forums/linux-unix/1646681-camilladsp-for-picoreplayer).