#!/bin/sh -e

ALSA_CDSP_VERSION="a2a16745581cc3da7b28df14f4fdf169d6452f89" # https://github.com/spfenwick/alsa_cdsp/commits/master/
CDSP_VERSION="v3.0.1"  # https://github.com/HEnquist/camilladsp/releases/
CAMILLA_GUI_VERSION="v3.0.3"  # https://github.com/HEnquist/camillagui-backend/releases

BUILD_DIR="/tmp/piCoreCDSP"
CACHE_DIR="/mnt/mmcblk0p2/tce/piCoreCDSP-cache"

### Decide for 64bit or 32bit installation
if [ "aarch64" = "$(uname -m)" ]; then
  architecture="aarch64"
else
  architecture="armv7"
fi

show_usage() {
  echo "Optional arguments:"
  echo "-k | --keep-downloads    Keep downloads"
}

keepDownloads=false
if [ $# -gt 0 ]; then
  for parameter in "$@"
  do
      case "${parameter}" in
          -k|--keep-downloads) keepDownloads=true;;
          *) show_usage; exit 1;;
      esac
  done
fi

$keepDownloads && echo "Keeping downloads."

# Installs a module from the piCorePlayer repository - if not already installed.
# Call like this: install_if_missing module_name
install_if_missing(){
  if tce-status -u | grep -q "$1" ; then
    pcp-load -il "$1"
  elif ! tce-status -i | grep -q "$1" ; then
    pcp-load -wil "$1"
  fi
}

# Installs a module from the piCorePlayer repository, at least until the next reboot - if not already installed.
# Call like this: install_temporarily_if_missing module_name
install_temporarily_if_missing(){
  if tce-status -u | grep -q "$1" ; then
    pcp-load -il "$1"
  elif ! tce-status -i | grep -q "$1" ; then
    if $keepDownloads; then
      pcp-load -wil "$1"
    else
      pcp-load -wil -t /tmp "$1" # Downloads to /tmp/optional and loads extensions temporarily
    fi
  fi
}

# Call like this: download_and_extract_tar_gz localFileName URL
download_and_extract_tar_gz() {
  localFileName=$1
  url=$2
  echo "Downloading $url as $localFileName"
  if $keepDownloads; then
    lastDir=$(pwd)
    mkdir -p "$CACHE_DIR"
    cd "$CACHE_DIR"
    if [ ! -f "$localFileName" ]; then
      wget -O "$localFileName" "$url"
    else
      echo "Already downloaded $CACHE_DIR/$localFileName"
    fi
    cd "$lastDir"
    echo "Changed back to $lastDir"
    ln -s -T "$CACHE_DIR/$localFileName" "$localFileName"
  else
    wget -O "$localFileName" "$url"
  fi
  tar -xvf "$localFileName"
  rm -f "$localFileName"
}

### Abort, if piCoreCDSP extension is already installed
if [ -f "/etc/sysconfig/tcedir/optional/piCoreCDSP.tcz" ]; then
    >&2 echo "Uninstall the piCoreCDSP Extension and reboot, before installing it again"
    >&2 echo "In Main Page > Extensions > Installed > select 'piCoreCDSP.tcz' and press 'Delete'"
    exit 1
fi

### Exit, if not enough free space
requiredSpaceInMB=100
availableSpaceInMB=$(/bin/df -m /dev/mmcblk0p2 | awk 'NR==2 { print $4 }')
if [ "$availableSpaceInMB" -le $requiredSpaceInMB ]; then
    >&2 echo "Not enough free space"
    >&2 echo "Increase SD-Card size: Main Page > Additional functions > Resize FS"
    exit 1
fi

### Ensure fresh build dir exists
if [ -d $BUILD_DIR ]; then
    >&2 echo "Reboot before running the script again."
    exit 1
fi
mkdir -p $BUILD_DIR

set -v


### Creating CDSP data folders with default configuration

cd /mnt/mmcblk0p2/tce
mkdir -p camilladsp/configs
mkdir -p camilladsp/coeffs
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
    device:  "null"
    format: S16LE
filters: {}
mixers: {}
pipeline: []
processors: {}
' > default_config.yml

/bin/cp default_config.yml configs/Null.yml
echo "title: 'Null'
description: 'THIS CONFIGURATION WILL BE OVERWRITTEN WHEN piCoreCDSP IS REINSTALLED/UPDATED.

  DON''T SET UP YOUR CONFIGURATION HERE


  This is a minimal configuration to verify that CamillaDSP is working.

  The audio is just discarded, so you can''t hear anything.

  You have to set up the \"Playback device\" in the \"Devices\" tab and apply your changes.'
" >> configs/Null.yml

echo '
config_path: /mnt/mmcblk0p2/tce/camilladsp/configs/Null.yml
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


### Building ALSA CDSP plugin

install_temporarily_if_missing git
install_temporarily_if_missing compiletc
install_temporarily_if_missing libasound-dev

cd /tmp
git clone https://github.com/spfenwick/alsa_cdsp.git
cd /tmp/alsa_cdsp
git checkout $ALSA_CDSP_VERSION
make
sudo make install
cd /tmp
rm -rf alsa_cdsp/

cd $BUILD_DIR
mkdir -p usr/local/lib/alsa-lib/
sudo mv /usr/local/lib/alsa-lib/libasound_module_pcm_cdsp.so usr/local/lib/alsa-lib/libasound_module_pcm_cdsp.so


### Installing ALSA CDSP config

sudo chmod 664 /etc/asound.conf
sudo chown root:staff /etc/asound.conf

# Remove old configuration, in case it was installed before
asound_conf=$(
  cat /etc/asound.conf |
   tr '\n' '\r' |
    sed 's|\r\r# For more info about this configuration see: .*\rpcm.camilladsp.*\r}\r# pcm.camilladsp||' |
     tr '\r' '\n'
)
echo "$asound_conf" > /etc/asound.conf

echo '
# For more info about this configuration see: https://github.com/spfenwick/alsa_cdsp
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


### Set Squeezelite, Shairport and Bluetooth output to CamillaDSP

sed 's|^OUTPUT=.*|OUTPUT="camilladsp"|' -i /usr/local/etc/pcp/pcp.cfg
sed 's|^SHAIRPORT_OUT=.*|SHAIRPORT_OUT="camilladsp"|' -i /usr/local/etc/pcp/pcp.cfg
sed 's|^SHAIRPORT_CONTROL=.*|SHAIRPORT_CONTROL=""|' -i /usr/local/etc/pcp/pcp.cfg
sed 's|^BT_OUT_DEVICE=.*|BT_OUT_DEVICE="camilladsp"|' -i /usr/local/etc/pcp/pcp.cfg


### Downloading CamillaDSP

mkdir -p ${BUILD_DIR}/usr/local/
cd ${BUILD_DIR}/usr/local/
download_and_extract_tar_gz \
  "camilladsp-${CDSP_VERSION}-${architecture}.tar.gz" \
  "https://github.com/HEnquist/camilladsp/releases/download/${CDSP_VERSION}/camilladsp-linux-${architecture}.tar.gz"


### Building CamillaGUI

mkdir -p ${BUILD_DIR}/usr/local/
cd ${BUILD_DIR}/usr/local/
download_and_extract_tar_gz \
  "camillagui-${CAMILLA_GUI_VERSION}-${architecture}.tar.gz" \
  "https://github.com/HEnquist/camillagui-backend/releases/download/${CAMILLA_GUI_VERSION}/bundle_linux_${architecture}.tar.gz"
chmod -R 775 camillagui_backend
sudo chown root:staff camillagui_backend
echo '
camilla_host: "0.0.0.0"
camilla_port: 1234
bind_address: "0.0.0.0"
port: 5000
ssl_certificate: null
ssl_private_key: null
gui_config_file: null
config_dir: "/mnt/mmcblk0p2/tce/camilladsp/configs"
coeff_dir: "/mnt/mmcblk0p2/tce/camilladsp/coeffs"
default_config: "/mnt/mmcblk0p2/tce/camilladsp/default_config.yml"
statefile_path: "/mnt/mmcblk0p2/tce/camilladsp/camilladsp_statefile.yml"
log_file: "/tmp/camilladsp.log"
on_set_active_config: null
on_get_active_config: null
supported_capture_types: ["Stdin", "Alsa"]
supported_playback_types: ["Alsa"]
' > camillagui_backend/_internal/config/camillagui.yml


### Creating autorun script

mkdir -p ${BUILD_DIR}/usr/local/tce.installed/
cd ${BUILD_DIR}/usr/local/tce.installed/
echo "#!/bin/sh

/usr/local/camillagui_backend/camillagui_backend &" > piCoreCDSP
chmod 775 piCoreCDSP


### Building and installing piCoreCDSP extension

cd /tmp
install_temporarily_if_missing squashfs-tools
mksquashfs piCoreCDSP piCoreCDSP.tcz
mv -f piCoreCDSP.tcz /etc/sysconfig/tcedir/optional
echo piCoreCDSP.tcz >> /etc/sysconfig/tcedir/onboot.lst


### Saving changes and rebooting

pcp backup
pcp reboot
