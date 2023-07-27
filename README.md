# piCoreCDSP

The goal of this project is, to provide an easy way to install CamillaDSP on a piCorePlayer installation.
This guide assumes a fresh piCorePlayer 8.2.0 64Bit install without any modifications.

# How to install

1. Increase piCorePlayer SD Card size to at least 200MB
   - in `Main Page > Additional functions > Resize FS`
   - select `200 MB` or one of the larger options
2. Run `install_cdsp.sh` on piCorePlayer:
   - SSH onto the piCorePlayer
     - usually `ssh tc@pcp.local` or `ssh tc@<IP of your piCorePlayer>` with password `piCore`
     - [How to find the IP adress of your piCorePlayer](https://docs.picoreplayer.org/how-to/determine_your_pcp_ip_address/) 
   - run `wget https://github.com/JWahle/piCoreCDSP/raw/main/install_cdsp.sh && chmod u+x install_cdsp.sh && ./install_cdsp.sh`
3. Open CamillaGUI in the browser:
   - will be running on port 5000 of piCorePlayer.
     Usually can be opened with `pcp.local:5000` or `<IP of your piCorePlayer>:5000`
   - under `Playback device` enter the settings for your DAC (by default, the Raspi headphone output is used)
     - These HAVE TO BE CORRECT, otherwise CamillaDSP will not start!
       - `device`: The Alsa device name of the DAC
         - a list of available devices can be found in `Squeezelite settings > Output setting`
         - if you know the `sampleformat` for your DAC or want to find it through trial and error,
           then choose a device with `hw:` prefix. Otherwise, use one with `plughw:` prefix. 
       - `channels`: a supported channel count for the DAC
       - `sampleformat`: a supported sample format for the DAC. (Only important, when NOT using a `plughw:` device)
   - Hit `Apply and save`
   - You should see channel meters and `State: RUNNING` on the left

# Implementation

The `install_cdsp.sh` script downloads the following projects including dependencies and runs them with convenient default settings:
- https://github.com/scripple/alsa_cdsp
- https://github.com/HEnquist/camilladsp
- https://github.com/HEnquist/camillagui-backend
- additional configuration files are located in the `files` folder