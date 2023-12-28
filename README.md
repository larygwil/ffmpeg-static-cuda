# ffmpeg-static-cuda

## Download and use

Download from the releases. 

Static ffmpeg binary for Linux with cuda (nvenc, cuvid(nvdec)), h264(avc), h265(hevc)

Also have binaries that work on some old Nvidia gpus.

Use cuda utilites to see if it can find your gpu, first.

## How to build a static ffmpeg with cuda

See the shell scripts.

If you want to use on old Nvidia gpu, you can download my binaries, or compile one yourself. (Although, buying a new gpu is better.)

Use old cuda (see the url text file)
- Cuda 9.1 requires gcc <= 6
- Cuda 7.5 requires gcc == 4.8

Old gcc means you can't compile new ffmpeg. Use old.

Use nv-codec-headers old version if you want to use on old gpus

See the shell scripts. Good luck.
