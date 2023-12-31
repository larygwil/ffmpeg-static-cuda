# ffmpeg-static-cuda

## Download and use

Download from the releases. 

Static ffmpeg binary for Linux with cuda (nvenc, cuvid(nvdec)), h264(avc), h265(hevc)

Also have binaries that work on some old Nvidia gpus.

Use cuda utilites to see if it can find your gpu, first.

## How to build a static ffmpeg with cuda

See the shell scripts.

If you want to use on old Nvidia gpu, you can download my binaries, or compile one yourself. (Although, buying a new gpu is better.)


Old gcc means you can't compile new ffmpeg. Use old.

Use nv-codec-headers old version if you want to use on old gpus

See the shell scripts. Good luck.

```
CUDA version 	max supported GCC version
12.1, 12.2, 12.3 	12.2
12 	12.1
11.4.1+, 11.5, 11.6, 11.7, 11.8 	11
11.1, 11.2, 11.3, 11.4.0 	10
11 	9
10.1, 10.2 	8
9.2, 10.0 	7
9.0, 9.1 	6
8 	5.3
7 	4.9
5.5, 6 	4.8
4.2, 5 	4.6
4.1 	4.5
4.0 	4.4
```

```
CUDA ver 	capatibility supported 	arch
3.0 – 3.1 	1.0 – 2.0 	Tesla, Fermi 	
3.2 	1.0 – 2.1 	Tesla, Fermi 	
4.0 – 4.2 	1.0 – 2.1+x 	Tesla, Fermi 	
5.0 – 5.5 	1.0 – 3.5 	Tesla, Fermi, Kepler 	
6.0 	1.0 – 3.5 	Tesla, Fermi, Kepler 	
6.5 	1.1 – 5.x 	Tesla, Fermi, Kepler, Maxwell 	最後支援計算能力 1.x (Tesla) 的版本
7.0 – 7.5 	2.0 – 5.x 	Fermi, Kepler, Maxwell 	
8.0 	2.0 – 6.x 	Fermi, Kepler, Maxwell, Pascal 	最後支援計算能力 2.x (Fermi) 的版本；GTX 1070Ti 不受支援 
9.0 no fermi
```
