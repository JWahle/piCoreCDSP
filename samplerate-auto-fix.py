import os
import re
import subprocess
import time
from typing import Optional

from camilladsp import CamillaClient, CamillaError


cdsp_ip = "127.0.0.1"
cdsp_port = 1234


def main():
    print("Monitoring samplerate...")
    while True:
        try:
            restart_cdsp_if_necessary()
            cdsp = CamillaClient(cdsp_ip, cdsp_port)
            connect_to_cdsp_if_necessary(cdsp)
            alsa_samplerate = get_alsa_samplerate()
            cdsp_samplerate = get_cdsp_samplerate(cdsp)
            print("CDSP samplerate: " + str(cdsp_samplerate))
            print("ALSA samplerate: " + str(alsa_samplerate))
            if alsa_samplerate != cdsp_samplerate:
                apply_alsa_samplerate(cdsp, alsa_samplerate)
        except CamillaError:
            print("Could not connect to CamillaDSP")
        except Exception as e:
            print(e)
        time.sleep(2)


def restart_cdsp_if_necessary():
    stream = os.popen('ps -ef')
    open_processes = stream.readlines()
    for s in open_processes:
        if "/usr/local/camilladsp" in s:
            print("CamillaDSP is running")
            return
    print("Restarting CamillaDSP")
    subprocess.Popen(
        "/usr/local/camilladsp -p 1234 -a 0.0.0.0 -o /tmp/camilladsp.log --statefile /mnt/mmcblk0p2/tce/camilladsp/camilladsp_statefile.yml",
        shell=True,
        text=True,
        close_fds=True)


def connect_to_cdsp_if_necessary(cdsp: CamillaClient):
    if not cdsp.is_connected():
        cdsp.connect()


def get_cdsp_samplerate(cdsp: CamillaClient) -> Optional[int]:
    return cdsp.rate.capture()


def get_alsa_samplerate():
    # stream = os.popen('cat /proc/asound/UltraLitemk5/pcm0c/sub0/hw_params | grep "rate: "')
    stream = os.popen('cat /proc/asound/DAC8PRO/pcm0c/sub0/hw_params | grep "rate: "')
    output = stream.read()
    rate_output_row = re.search('rate: (\d+).*', output)
    rate_string = rate_output_row.group(1)
    return int(rate_string)


def apply_alsa_samplerate(cdsp: CamillaClient, samplerate: int):
    config = cdsp.config.active()
    config['devices']['capture_samplerate'] = samplerate
    cdsp.config.set_active(config)
    print("Updated config with samplerate " + str(samplerate))


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        pass
