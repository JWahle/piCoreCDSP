#!/bin/sh -e

### Exit, if not enough free space
requiredSpaceInMB=100
availableSpaceInMB=$(/bin/df -m /dev/mmcblk0p2 | awk 'NR==2 { print $4 }')
if [[ $availableSpaceInMB -le $requiredSpaceInMB ]]; then
    >&2 echo "Not enough free space"
    >&2 echo "Increase SD-Card size: Main Page > Additional functions > Resize FS"
    exit 1
fi

### Abort, if piCoreCDSP extension is already installed
if [ -f "/etc/sysconfig/tcedir/optional/piCoreCDSP.tcz" ]; then
    >&2 echo "Uninstall the piCoreCDSP Extension and reboot, before installing it again"
    >&2 echo "In Main Page > Extensions > Installed > select 'piCoreCDSP.tcz' and press 'Delete'"
    exit 1
fi

### Decide for 64bit or 32bit installation
if [ "aarch64" = "$(uname -m)" ]; then
    use32bit=false
else
    use32bit=true
fi

if [ -d "/tmp/piCoreCDSP" ]; then
    >&2 echo "Reboot before running the script again."
    exit 1
fi
mkdir -p /tmp/piCoreCDSP

# Installs a module from the piCorePlayer repository - if not already installed.
# Call like this: install_if_missing module_name
install_if_missing(){
  if ! tce-status -i | grep -q "$1" ; then
    pcp-load -wil "$1"
  fi
}

# Installs a module from the piCorePlayer repository, at least until the next reboot - if not already installed.
# Call like this: install_temporarily_if_missing module_name
install_temporarily_if_missing(){
  if ! tce-status -i | grep -q "$1" ; then
    pcp-load -wil -t /tmp "$1" # Downloads to /tmp/optional and loads extensions temporarily
  fi
}

set -v

### Create CamillaDSP config folders

cd /mnt/mmcblk0p2/tce
mkdir -p camilladsp/configs
mkdir -p camilladsp/coeffs

### Create default config

cd /mnt/mmcblk0p2/tce/camilladsp
echo '
devices:
  samplerate: 44100
  chunksize: 2048
  queuelimit: 4
  capture:
    type: Stdin
    channels: 2
    format: S16LE
  playback:
    type: Alsa
    channels: 2
    device: "plughw:Headphones"
    format: S16LE
' > default_config.yml
/bin/cp default_config.yml configs/Headphones.yml

echo '
config_path: /mnt/mmcblk0p2/tce/camilladsp/configs/Headphones.yml
mute:
- false
- false
- false
- false
- false
volume:
- 0.0
- 0.0
- 0.0
- 0.0
- 0.0
' > camilladsp_statefile.yml

### Install ALSA CDSP

cd /tmp

install_temporarily_if_missing git
install_temporarily_if_missing compiletc
install_temporarily_if_missing libasound-dev

git clone https://github.com/spfenwick/alsa_cdsp.git
cd /tmp/alsa_cdsp
git checkout 6c4d4a1d2dee286415916f6663cc4498a0a1e250
make
sudo make install
cd /tmp
rm -rf alsa_cdsp/
cd /tmp

sudo chmod 664 /etc/asound.conf
sudo chown root:staff /etc/asound.conf
# Remove old configuration, in case it was installed before
cat /etc/asound.conf |\
 tr '\n' '\r' |\
  sed 's|\r\r# For more info about this configuration see: https://github.com/scripple/alsa_cdsp\rpcm.camilladsp.*\r}\r# pcm.camilladsp||' |\
   tr '\r' '\n' > /tmp/asound.conf
cat /tmp/asound.conf > /etc/asound.conf
echo '
# For more info about this configuration see: https://github.com/scripple/alsa_cdsp
pcm.camilladsp {
    type cdsp
    cpath "/usr/local/camilladsp"

####################################
# Set the values for your DAC here #
####################################
    min_channels 1
    max_channels 8
    rates = [
        44100
        48000
        88200
        96000
        176400
        192000
        352800
        384000
    ]

   cargs [
# Uncomment, if you want more detailed logging output
#        -v
        -p "1234"
        -a "0.0.0.0"
        -o "/tmp/camilladsp.log"
        --statefile "/mnt/mmcblk0p2/tce/camilladsp/camilladsp_statefile.yml"
   ]

}
# pcm.camilladsp
' >> /etc/asound.conf

### Set Squeezelite and Shairport output to camilladsp

sed 's/^OUTPUT=.*/OUTPUT="camilladsp"/' -i /usr/local/etc/pcp/pcp.cfg
sed 's/^SHAIRPORT_OUT=.*/SHAIRPORT_OUT="camilladsp"/' -i /usr/local/etc/pcp/pcp.cfg

### Install CamillaGUI

install_if_missing python3.8
install_temporarily_if_missing python3.8-pip
$use32bit && install_temporarily_if_missing python3.8-dev
sudo mkdir -m 775 /usr/local/camillagui
sudo chown root:staff /usr/local/camillagui
cd /usr/local/camillagui
python3 -m venv environment
(tr -d '\r' < environment/bin/activate) > environment/bin/activate_new # Create fixed version of the activate script. See https://stackoverflow.com/a/44446239
mv -f environment/bin/activate_new environment/bin/activate
source environment/bin/activate # activate custom python environment
python3 -m pip install --upgrade pip
pip install websocket_client aiohttp jsonschema setuptools
pip install git+https://github.com/HEnquist/pycamilladsp.git@v2.0.0
pip install git+https://github.com/HEnquist/pycamilladsp-plot.git@v2.0.0
deactivate # deactivate custom python environment
wget https://github.com/HEnquist/camillagui-backend/releases/download/v2.0.0/camillagui.zip
unzip camillagui.zip
rm -f camillagui.zip
echo '
---
camilla_host: "0.0.0.0"
camilla_port: 1234
port: 5000
config_dir: "/mnt/mmcblk0p2/tce/camilladsp/configs"
coeff_dir: "/mnt/mmcblk0p2/tce/camilladsp/coeffs"
default_config: "/mnt/mmcblk0p2/tce/camilladsp/default_config.yml"
statefile_path: "/mnt/mmcblk0p2/tce/camilladsp/camilladsp_statefile.yml"
log_file: "/tmp/camilladsp.log"
on_set_active_config: null
on_get_active_config: null
supported_capture_types: ["Stdin", "Alsa"]
supported_playback_types: ["Alsa"]
' > config/camillagui.yml

touch /mnt/mmcblk0p2/tce/camilladsp/camilladsp_statefile.yml

### Create and install piCoreCDSP.tcz

mkdir -p /tmp/piCoreCDSP/usr/local/

cd /tmp/piCoreCDSP/usr/local/

if $use32bit; then
    wget https://github.com/HEnquist/camilladsp/releases/download/v2.0.0/camilladsp-linux-armv7.tar.gz
    tar -xvf camilladsp-linux-armv7.tar.gz
    rm -f camilladsp-linux-armv7.tar.gz
else
    wget https://github.com/HEnquist/camilladsp/releases/download/v2.0.0/camilladsp-linux-aarch64.tar.gz
    tar -xvf camilladsp-linux-aarch64.tar.gz
    rm -f camilladsp-linux-aarch64.tar.gz
fi

cd /tmp/piCoreCDSP/

mkdir -p usr/local/lib/alsa-lib/
sudo mv /usr/local/lib/alsa-lib/libasound_module_pcm_cdsp.so usr/local/lib/alsa-lib/libasound_module_pcm_cdsp.so

sudo mv /usr/local/camillagui usr/local/

mkdir -p usr/local/tce.installed/
echo "#!/bin/sh

sudo -u tc sh -c 'while [ ! -f /usr/local/bin/python3 ]; do sleep 1; done
source /usr/local/camillagui/environment/bin/activate
python3 /usr/local/camillagui/main.py &' &" > usr/local/tce.installed/piCoreCDSP
chmod 775 usr/local/tce.installed/piCoreCDSP

cd /tmp
install_temporarily_if_missing squashfs-tools
mksquashfs piCoreCDSP piCoreCDSP.tcz
mv -f piCoreCDSP.tcz /etc/sysconfig/tcedir/optional
echo "python3.8.tcz" > /etc/sysconfig/tcedir/optional/piCoreCDSP.tcz.dep
echo piCoreCDSP.tcz >> /etc/sysconfig/tcedir/onboot.lst

### Save Changes

pcp backup
pcp reboot