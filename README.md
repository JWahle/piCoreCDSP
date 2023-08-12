# piCoreCDSP
The goal of this project is to provide an easy way to install CamillaDSP including GUI and automatic samplerate switching on a piCorePlayer installation.

## Requirements
- a fresh piCorePlayer 8.2.0 installation without any modifications
- on an armv7 or arch64 device

## How to install
1. Increase piCorePlayer SD Card size to at least 200MB
   - In `Main Page > Additional functions > Resize FS`
   - Select `200 MB` or one of the larger options
2. Run `install_cdsp.sh` on piCorePlayer:
   - SSH onto the piCorePlayer
     - Usually `ssh tc@pcp.local` or `ssh tc@<IP of your piCorePlayer>` with password `piCore`
     - [How to find the IP adress of your piCorePlayer](https://docs.picoreplayer.org/how-to/determine_your_pcp_ip_address/) 
   - On 64bit piCorePlayer run   
     `wget https://github.com/JWahle/piCoreCDSP/raw/main/install_cdsp.sh && chmod u+x install_cdsp.sh && ./install_cdsp.sh`
   - On 32bit piCorePlayer run  
     `wget https://github.com/JWahle/piCoreCDSP/raw/main/install_cdsp.sh && chmod u+x install_cdsp.sh && ./install_cdsp.sh 32bit`
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
       - `sampleformat`: a supported sample format for the DAC. (Only important, when NOT using a `plughw:` device)
   - Hit `Apply and save`
     - You should see channel meters and `State: RUNNING` on the left
     - If things go wrong, check the CamillaDSP log file via the `Show log file` button for more info

## Implementation
The `install_cdsp.sh` script downloads the following projects including dependencies and installs them with convenient default settings:
- https://github.com/scripple/alsa_cdsp
- https://github.com/HEnquist/camilladsp
- https://github.com/HEnquist/camillagui-backend

## For developers
If you made some changes to the script and want to run it quickly on the piCorePlayer, run  
`scp install_cdsp.sh tc@pcp.local:~ && ssh tc@pcp.local "./install_cdsp.sh"`  
or for 32bit:  
`scp install_cdsp.sh tc@pcp.local:~ && ssh tc@pcp.local "./install_cdsp.sh 32bit"`  
If your piCorePlayer is not available on [pcp.local](http://pcp.local),
replace both occurrences of `pcp.local` with the IP-Adress of your piCorePlayer.