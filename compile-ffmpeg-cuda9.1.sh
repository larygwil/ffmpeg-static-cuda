#!/bin/bash

# build static ffmpeg with nvenc in ubuntu 18.04 on Codespace
#   use Dockerfile:
#     ARG VARIANT=ubuntu-18.04
#     FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# ffmpeg 4.4 ,  cuda 9.1 (require gcc<=6) , nv-codec-headers 8.1 , gcc 6 
# should work on nvidia driver 390

# Original texts:
# https://gist.github.com/ransagy/3f6f1a9e5ede6212425f3b36b136216e
# #       It also relies on a hack described in https://trac.ffmpeg.org/ticket/6431#comment:7 to make glibc dynamic still.
# #       Long story short, you need to edit your ffmepg's configure script to avoid failures on libm and libdl.
# #         in function probe_cc, replace the _flags_filter=echo line to: _flags_filter='filter_out -lm|-ldl'



# Below are some list after finish build ( not all listed)
# 
# Encoders:
# V..... = Video
# A..... = Audio
# S..... = Subtitle
# .F.... = Frame-level multithreading
# ..S... = Slice-level multithreading
# ...X.. = Codec is experimental
# ....B. = Supports draw_horiz_band
# .....D = Supports direct rendering method 1
# V..... libx264              libx264 H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 (codec h264)
# V..... libx264rgb           libx264 H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10 RGB (codec h264)
# V....D h264_nvenc           NVIDIA NVENC H.264 encoder (codec h264)
# V..... h264_v4l2m2m         V4L2 mem2mem H.264 encoder wrapper (codec h264)
# V..... nvenc                NVIDIA NVENC H.264 encoder (codec h264)
# V..... nvenc_h264           NVIDIA NVENC H.264 encoder (codec h264)
# V..... nvenc_hevc           NVIDIA NVENC hevc encoder (codec hevc)
# V....D hevc_nvenc           NVIDIA NVENC hevc encoder (codec hevc)
# V..... hevc_v4l2m2m         V4L2 mem2mem HEVC encoder wrapper (codec hevc)
# V..... libvpx               libvpx VP8 (codec vp8)
# V..... vp8_v4l2m2m          V4L2 mem2mem VP8 encoder wrapper (codec vp8)
# V..... libvpx-vp9           libvpx VP9 (codec vp9)
# 
# 
# Decoders:
# V..... = Video
# A..... = Audio
# S..... = Subtitle
# .F.... = Frame-level multithreading
# ..S... = Slice-level multithreading
# ...X.. = Codec is experimental
# ....B. = Supports draw_horiz_band
# .....D = Supports direct rendering method 1
# VFS..D h264                 H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10
# V..... h264_v4l2m2m         V4L2 mem2mem H.264 decoder wrapper (codec h264)
# V..... h264_cuvid           Nvidia CUVID H264 decoder (codec h264)
# VFS..D hevc                 HEVC (High Efficiency Video Coding)
# V..... hevc_v4l2m2m         V4L2 mem2mem HEVC decoder wrapper (codec hevc)
# V..... hevc_cuvid           Nvidia CUVID HEVC decoder (codec hevc)
# VFS..D vp8                  On2 VP8
# V..... vp8_v4l2m2m          V4L2 mem2mem VP8 decoder wrapper (codec vp8)
# V....D libvpx               libvpx VP8 (codec vp8)
# V..... vp8_cuvid            Nvidia CUVID VP8 decoder (codec vp8)
# VFS..D vp9                  Google VP9
# V..... vp9_v4l2m2m          V4L2 mem2mem VP9 decoder wrapper (codec vp9)
# V..... libvpx-vp9           libvpx VP9 (codec vp9)
# V..... vp9_cuvid            Nvidia CUVID VP9 decoder (codec vp9)
# 
# Hardware acceleration methods:
# vdpau
# cuda
# 
# Devices:
# D. = Demuxing supported
# .E = Muxing supported
# --
# DE fbdev           Linux framebuffer
# D  lavfi           Libavfilter virtual input device
# DE oss             OSS (Open Sound System) playback
# DE video4linux2,v4l2 Video4Linux2 output device
# D  x11grab         X11 screen capture, using XCB


#install required things from apt
installLibs(){
echo "Installing prerequisites"
sudo apt-get update  && \
sudo apt-get -y --force-yes install autoconf automake build-essential libfreetype6-dev libgpac-dev \
  libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texi2html zlib1g-dev libvpx-dev \
  libharfbuzz-dev libfontconfig-dev   || exit 1
}

installCUDA(){
wget https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/cuda_9.1.85_387.26_linux \
  -O /tmp/cuda-9-1.run   && \
chmod a+x /tmp/cuda-9-1.run  && \
sudo /tmp/cuda-9-1.run --silent --toolkit --override --samples || return 1
export PATH=$PATH:/usr/local/cuda-9.1/bin
export LD_LIBRARY_PATH=/usr/local/cuda-9.1/lib64:$LD_LIBRARY_PATH
}


#Install nvidia SDK
installSDK(){
echo "Installing the nVidia NVENC SDK using the latest supported 8.1 tag."
cd ~/ffmpeg_sources
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git  && \
cd nv-codec-headers  && \
# git checkout -b sdk90 n9.0.18.3
git checkout sdk/8.1  && \
make  && \
sudo make install
}

#Compile nasm
compileNasm(){
echo "Compiling nasm"
cd ~/ffmpeg_sources
wget http://www.nasm.us/pub/nasm/releasebuilds/2.14rc0/nasm-2.14rc0.tar.gz  && \
tar xzvf nasm-2.14rc0.tar.gz  && \
cd nasm-2.14rc0  && \
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-shared  && \
make -j$(nproc)  && \
make -j$(nproc) install
# make -j$(nproc) distclean
}

#Compile libx264
compileLibX264(){
echo "Compiling libx264"
cd ~/ffmpeg_sources
git clone https://code.videolan.org/videolan/x264.git  && \
cd x264  && \
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static --disable-shared  && \
PATH="$HOME/bin:$PATH" make -j$(nproc)  && \
make -j$(nproc) install
# make -j$(nproc) distclean
}

#Compile libfdk-acc
compileLibfdkcc(){
echo "Compiling libfdk-cc"
sudo apt-get install unzip || exit 1
cd ~/ffmpeg_sources  && \
wget -O fdk-aac.zip https://github.com/mstorsjo/fdk-aac/zipball/master  && \
unzip -o fdk-aac.zip  && \
cd mstorsjo-fdk-aac*  && \
autoreconf -fiv  && \
./configure --prefix="$HOME/ffmpeg_build" --enable-static --disable-shared  && \
make -j$(nproc)  && \
make -j$(nproc) install
# make -j$(nproc) distclean
}

#Compile libmp3lame
compileLibMP3Lame(){
echo "Compiling libmp3lame"
sudo apt-get install nasm  || exit 1
cd ~/ffmpeg_sources  || exit 1
wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz  && \
tar xzvf lame-3.99.5.tar.gz  && \
cd lame-3.99.5  && \
./configure --prefix="$HOME/ffmpeg_build" --enable-nasm --enable-static --disable-shared  && \
make -j$(nproc)  && \
make -j$(nproc) install
# make -j$(nproc) distclean
}

#Compile libopus
compileLibOpus(){
echo "Compiling libopus"
cd ~/ffmpeg_sources
wget http://downloads.xiph.org/releases/opus/opus-1.2.1.tar.gz  && \
tar xzvf opus-1.2.1.tar.gz  && \
cd opus-1.2.1  && \
./configure --prefix="$HOME/ffmpeg_build" --enable-static --disable-shared  && \
make -j$(nproc)  && \
make -j$(nproc) install
# make -j$(nproc) distclean
}

#Compile libvpx
compileLibPvx(){
echo "Compiling libvpx"
cd ~/ffmpeg_sources
git clone https://chromium.googlesource.com/webm/libvpx  && \
cd libvpx  && \
PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --enable-runtime-cpu-detect --enable-vp9 --enable-vp8 \
--enable-postproc --enable-vp9-postproc --enable-multi-res-encoding --enable-webm-io --enable-better-hw-compatibility --enable-vp9-highbitdepth --enable-onthefly-bitpacking --enable-realtime-only \
--cpu=native --as=nasm --enable-static --disable-shared
PATH="$HOME/bin:$PATH" make -j$(nproc)  && \
make -j$(nproc) install  && \
make -j$(nproc) clean
}

#Compile ffmpeg
compileFfmpeg(){
echo "Compiling ffmpeg"
cd ~/ffmpeg_sources
git clone https://github.com/FFmpeg/FFmpeg -b master
cd FFmpeg
git checkout release/4.4 && \
sed -i "s/_flags_filter=echo/_flags_filter='filter_out -lm|-ldl'/g" configure  && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --extra-cflags="-I$HOME/ffmpeg_build/include -I/usr/local/cuda/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib -L/usr/local/cuda/lib64" \
  --extra-ldexeflags="-Wl,-Bstatic" \
  --extra-libs="-Wl,-Bdynamic -lm -ldl" \
  --pkg-config-flags="--static" \
  --bindir="$HOME/bin" \
  --disable-debug \
  --enable-static \
  --enable-gpl \
  --enable-nonfree \
  --enable-version3 \
  --enable-libmp3lame \
  --enable-libfdk-aac \
  --enable-libopus \
  --enable-libvpx \
  --enable-libx264 \
  --enable-cuvid \
  --enable-libfreetype  \
  --enable-nvenc   && \
PATH="$HOME/bin:$PATH" make -j$(nproc)   && \
make -j$(nproc) install
# make -j$(nproc) distclean
hash -r
}

#The process
cd ~
mkdir -p ffmpeg_sources
installLibs || exit 1
installCUDA || exit
installSDK || exit 1
compileNasm || exit 1
compileLibX264 || exit 1
compileLibMP3Lame || exit 1
compileLibfdkcc || exit 1
compileLibOpus || exit 1
compileLibPvx || exit 1
compileFfmpeg || exit 1
echo "Complete!"