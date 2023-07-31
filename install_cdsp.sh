#!/bin/sh

### Abort, if piCoreCDSP extension is already installed
if [ -f "/etc/sysconfig/tcedir/optional/piCoreCDSP.tcz" ]; then
    echo "Uninstall the piCoreCDSP Extension and reboot, before installing it again"
    echo "(In Main Page > Extensions > Installed > select 'piCoreCDSP.tcz' and press 'Delete')"
    exit
fi

### Check for 32bit mode
if [ "32bit" = "$1" ]; then
    use32bit=true
elif [ -z "$1" ]; then
    use32bit=false
else
  echo "$1 is not supported. Use '32bit' or no arguments."
  exit
fi

set -v

### Create CamillaDSP config folders

cd /mnt/mmcblk0p2/tce
mkdir camilladsp
mkdir camilladsp/configs
mkdir camilladsp/coeffs

### Download default config

cd /mnt/mmcblk0p2/tce/camilladsp
rm -f Headphones.yml
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
' > Headphones.yml
if [ ! -f "configs/Headphones.yml" ]; then
    cp Headphones.yml configs
fi
if [ ! -f "active_config" ]; then
    ln -s configs/Headphones.yml active_config
fi

### Install ALSA CDSP

cd /tmp
tce-load -wil -t /tmp git compiletc libasound-dev # Downloads to /tmp/optional and loads extensions temporarily
git clone https://github.com/scripple/alsa_cdsp.git
cd /tmp/alsa_cdsp
make
sudo make install
cd /tmp
rm -rf alsa_cdsp/
cd /tmp

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
    config_out "/mnt/mmcblk0p2/tce/camilladsp/active_config"

    # config_cdsp says to use the new CamillaDSP internal substitutions.
    # When config_cdsp is set to an integer != 0 the hw_params and
    # extra samples are passed to CamillaDSP on the command line as
    # -f format -r samplerate -n channels -e extra_samples
    config_cdsp 1

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
   ]

}
# pcm.camilladsp
' >> /etc/asound.conf

### Set Squeezelite and Shairport output to camilladsp

sed 's/^OUTPUT=.*/OUTPUT="camilladsp"/' -i /usr/local/etc/pcp/pcp.cfg
sed 's/^SHAIRPORT_OUT=.*/SHAIRPORT_OUT="camilladsp"/' -i /usr/local/etc/pcp/pcp.cfg

### Install CamillaGUI

tce-load -wil python3.8
tce-load -wil -t /tmp python3.8-pip # Downloads to /tmp/optional and loads extension temporarily
$use32bit && tce-load -wil -t /tmp python3.8-dev # Downloads to /tmp/optional and loads extension temporarily
sudo mkdir -m 775 /usr/local/camillagui
sudo chown root:staff /usr/local/camillagui
cd /usr/local/camillagui
python3 -m venv environment
(tr -d '\r' < environment/bin/activate) > environment/bin/activate_new # Create fixed version of the activate script. See https://stackoverflow.com/a/44446239
mv -f environment/bin/activate_new environment/bin/activate
source environment/bin/activate # activate custom python environment
python3 -m pip install --upgrade pip
pip install websocket_client aiohttp jsonschema setuptools
pip install git+https://github.com/HEnquist/pycamilladsp.git@v1.0.0
pip install git+https://github.com/HEnquist/pycamilladsp-plot.git@v1.0.2
deactivate # deactivate custom python environment
wget https://github.com/HEnquist/camillagui-backend/releases/download/v1.0.1/camillagui.zip
unzip camillagui.zip
rm -f camillagui.zip
echo '
---
camilla_host: "127.0.0.1"
camilla_port: 1234
port: 5000
config_dir: "/mnt/mmcblk0p2/tce/camilladsp/configs"
coeff_dir: "/mnt/mmcblk0p2/tce/camilladsp/coeffs"
default_config: "/mnt/mmcblk0p2/tce/camilladsp/default_config.yml"
active_config: "/mnt/mmcblk0p2/tce/camilladsp/active_config"
active_config_txt: "/mnt/mmcblk0p2/tce/camilladsp/active_config.txt"
log_file: "/tmp/camilladsp.log"
update_config_symlink: true
update_config_txt: false
on_set_active_config: null
on_get_active_config: null
supported_capture_types: ["Stdin"]
supported_playback_types: ["Alsa"]
' > config/camillagui.yml

### Create and install piCoreCDSP.tcz

mkdir -p /tmp/piCoreCDSP/usr/local/

cd /tmp/piCoreCDSP/usr/local/

if $use32bit; then
    wget https://github.com/HEnquist/camilladsp/releases/download/v1.0.3/camilladsp-linux-armv7.tar.gz
    tar -xvf camilladsp-linux-armv7.tar.gz
    rm -f camilladsp-linux-armv7.tar.gz
else
    wget https://github.com/HEnquist/camilladsp/releases/download/v1.0.3/camilladsp-linux-aarch64.tar.gz
    tar -xvf camilladsp-linux-aarch64.tar.gz
    rm -f camilladsp-linux-aarch64.tar.gz
fi

cd /tmp/piCoreCDSP/

mkdir -p usr/local/lib/alsa-lib/
mv /usr/local/lib/alsa-lib/libasound_module_pcm_cdsp.so usr/local/lib/alsa-lib/libasound_module_pcm_cdsp.so

sudo mv /usr/local/camillagui usr/local/

mkdir -p usr/local/tce.installed/
echo "#!/bin/sh

sudo -u tc sh -c 'while [ ! -f /usr/local/bin/python3 ]; do sleep 1; done
source /usr/local/camillagui/environment/bin/activate
python3 /usr/local/camillagui/main.py &' &" > usr/local/tce.installed/piCoreCDSP
chmod 775 usr/local/tce.installed/piCoreCDSP

cd /tmp
tce-load -wil -t /tmp squashfs-tools # Downloads to /tmp/optional and loads extension temporarily
mksquashfs piCoreCDSP piCoreCDSP.tcz
mv -f piCoreCDSP.tcz /etc/sysconfig/tcedir/optional
echo "python3.8.tcz" > /etc/sysconfig/tcedir/optional/piCoreCDSP.tcz.dep
echo piCoreCDSP.tcz >> /etc/sysconfig/tcedir/onboot.lst

### Save Changes

pcp backup
pcp reboot