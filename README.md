# piCoreCDSP
The goal of this project is to provide an easy way to install CamillaDSP 2.0.3 including GUI
and automatic samplerate switching on a [piCorePlayer](https://www.picoreplayer.org/) installation.

## Requirements
- a fresh piCorePlayer 9.2.0 installation without any modifications
- on an armv7 or arch64 compatible device

## How to install
1. Increase piCorePlayer SD Card size to at least 200MB via `Main Page > Additional functions > Resize FS`
2. Run `install_cdsp.sh` on piCorePlayer from a terminal:
   - SSH onto the piCorePlayer as user `tc`
     - Usually `ssh tc@pcp.local` or `ssh tc@<IP of your piCorePlayer>`
     - [How to find the IP address of your piCorePlayer](https://docs.picoreplayer.org/how-to/determine_your_pcp_ip_address/)
   - Run  
     `wget https://github.com/JWahle/piCoreCDSP/raw/main/install_cdsp.sh && chmod u+x install_cdsp.sh && ./install_cdsp.sh`
   - Or if you want to run a modified version of the script or an older version, see the [For developers and tinkerers](#for-developers-and-tinkerers) section
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
     - If things go wrong, check the CamillaDSP log file via the `Show log file` button for more info.
       After changing the settings, go to the pCP `Main Page` and press `Restart` to restart Squeezelite.
       If the settings are correct, the channel meters and `State: RUNNING` on the left side should be visible in CamillaGUI.

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

## How to update
I don't recommend trying to update, because it generally is not straight forward and involves some troubleshooting.
Just do a fresh install and enjoy life.

## How to uninstall
SSH onto the piCorePlayer and enter the following commands depending on what you want to uninstall.

### piCoreCDSP extension
If you want to uninstall without setting up piCorePlayer again,
you have to reconfigure your audio output device in the pCP UI.
Then uninstall the piCoreCDSP Extension
(In `Main Page > Extensions > Installed >` select `piCoreCDSP.tcz`, press `Delete`)
and reboot.

### piCoreCDSP installation script
`rm -f /home/tc/install_cdsp.sh`

### CamillaDSP sound device
Remove the `pcm.camilladsp` entry from `/etc/asound.conf`.
This is easy to do with the Nano text editor:
```shell
tce-load -wil -t /tmp nano
nano /etc/asound.conf
```

### CamillaDSP configuration files and filters
`rm -rf /etc/sysconfig/tcedir/camilladsp/`

### Save the changes
If you just restart, some changes will not be persistent. To make all your changes persistent, run:
`pcp backup`

## Implementation
The `install_cdsp.sh` script downloads the following projects including dependencies
and installs them with convenient default settings:
- https://github.com/spfenwick/alsa_cdsp.git (forked from https://github.com/scripple/alsa_cdsp)
- https://github.com/HEnquist/camilladsp
- https://github.com/HEnquist/camillagui-backend

### Audio Architecture
```mermaid
graph TD;
    A(Audio Source<br>SqueezeLite/AirPlay/Bluetooth) -- Opens audio stream --> B(CamillaDSP Alsa Plugin);
    B -- Starts and then sends audio to stdin of CamillaDSP.<br>This will show the green meters in CamillaGUI. --> C(CamillaDSP);
    C --> O(Audio output<br>Configured in your CDSP config);
```

## For developers and tinkerers

In this section it is assumed, that your piCorePlayer is available on [pcp.local](http://pcp.local).
If this is not the case, replace occurrences of `pcp.local` with the IP-address/hostname of your piCorePlayer.

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

### Running CamillaDSP standalone

You can run CamillaDSP standalone. This might be useful, if you want to capture audio from some audio device.
Although, in this case you won't be able to use any of the Squeezelite/airPlay/Bluetooth audio sources.

1. Go to `Tweaks > Audio Tweaks` and set `Squeezelite` to `no`.
2. Then go to `Tweaks > User commands` and set one of the commands to  
   `sudo -u tc sh -c '/usr/local/camilladsp -p 1234 -a 0.0.0.0 -o /tmp/camilladsp.log --statefile /mnt/mmcblk0p2/tce/camilladsp/camilladsp_statefile.yml'`  
   or if you want a fixed volume of e.g. -30dB, use this command:  
   `sudo -u tc sh -c '/usr/local/camilladsp -p 1234 -a 0.0.0.0 -o /tmp/camilladsp.log --statefile /mnt/mmcblk0p2/tce/camilladsp/camilladsp_statefile.yml -g-30'`
3. Save and reboot
