#!/bin/sh

if [ -f "/etc/sysconfig/tcedir/optional/piCoreCDSP.tcz" ]; then
    echo "Uninstall the piCoreCDSP Extension before installing it again"
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
wget -q https://github.com/JWahle/piCoreCDSP/raw/main/files/Headphones.yml
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
wget -q https://github.com/JWahle/piCoreCDSP/raw/main/files/camilladsp.conf

# Remove old configuration, in case it was installed before
cat /etc/asound.conf |\
 tr '\n' '\r' |\
  sed 's|\r\r# For more info about this configuration see: https://github.com/scripple/alsa_cdsp\rpcm.camilladsp.*\r}\r# pcm.camilladsp||' |\
   tr '\r' '\n' > /tmp/asound.conf
cat /tmp/asound.conf > /etc/asound.conf
cat camilladsp.conf >> /etc/asound.conf

### Set Squeezelite and Shairport output to camilladsp

sed 's/^OUTPUT=.*/OUTPUT="camilladsp"/' -i /usr/local/etc/pcp/pcp.cfg
sed 's/^SHAIRPORT_OUT=.*/SHAIRPORT_OUT="camilladsp"/' -i /usr/local/etc/pcp/pcp.cfg

### Install CamillaGUI

tce-load -wil python3.8
tce-load -wil -t /tmp python3.8-pip # Downloads to /tmp/optional and loads extension temporarily
mkdir /usr/local/camillagui
cd /usr/local/camillagui
python3 -m venv environment
(tr -d '\r' < environment/bin/activate) > environment/bin/activate_new # Create fixed version of the activate script. See https://stackoverflow.com/a/44446239
mv -f environment/bin/activate_new environment/bin/activate
source environment/bin/activate # activate custom python environment
pip install websocket_client aiohttp jsonschema setuptools
pip install git+https://github.com/HEnquist/pycamilladsp.git@v1.0.0
pip install git+https://github.com/HEnquist/pycamilladsp-plot.git@v1.0.2
deactivate # deactivate custom python environment
wget https://github.com/HEnquist/camillagui-backend/releases/download/v1.0.1/camillagui.zip
unzip camillagui.zip
rm -f camillagui.zip
rm -f config/camillagui.yml
wget -q -P config https://github.com/JWahle/piCoreCDSP/raw/main/files/camillagui.yml

### Create and install piCoreCDSP.tcz

mkdir -p /tmp/piCoreCDSP/usr/local/

cd /tmp/piCoreCDSP/usr/local/
wget https://github.com/HEnquist/camilladsp/releases/download/v1.0.3/camilladsp-linux-aarch64.tar.gz
tar -xvf camilladsp-linux-aarch64.tar.gz
rm -f camilladsp-linux-aarch64.tar.gz

cd /tmp/piCoreCDSP/

mkdir -p usr/local/lib/alsa-lib/
mv /usr/local/lib/alsa-lib/libasound_module_pcm_cdsp.so usr/local/lib/alsa-lib/libasound_module_pcm_cdsp.so

sudo cp -a /usr/local/camillagui usr/local/

mkdir -p usr/local/tce.installed/
echo "#!/bin/sh

sudo -u tc sh -c 'while [ ! -f /usr/bin/python3 ]; do sleep 1; done
source /usr/local/camillagui/environment/bin/activate
python3 /usr/local/camillagui/main.py &'" > usr/local/tce.installed/piCoreCDSP
chmod 775 usr/local/tce.installed/piCoreCDSP

cd /tmp
tce-load -wil -t /tmp squashfs-tools # Downloads to /tmp/optional and loads extension temporarily
mksquashfs piCoreCDSP piCoreCDSP.tcz
mv -f piCoreCDSP.tcz /etc/sysconfig/tcedir/optional
echo "python3.8.tcz" > /etc/sysconfig/tcedir/optional/piCoreCDSP.tcz.dep
cd /etc/sysconfig/tcedir
echo piCoreCDSP.tcz >> onboot.lst

### Save Changes

pcp backup
pcp reboot