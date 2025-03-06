while true; do
  if [ "$samplerate" -eq "44100" ]; then
    samplerate=48000
  else
    samplerate=44100
  fi
  /usr/local/camilladsp -p 1234 -a 0.0.0.0 --samplerate "$samplerate" --statefile /mnt/mmcblk0p2/tce/camilladsp/camilladsp_statefile.yml >> /tmp/camilladsp.log
done
