#!/bin/bash

# ffmpeg 3.4 ,  cuda 7.5 (require gcc<=4.8) , nv-codec-headers 8.0 

# Original texts:
# https://gist.github.com/ransagy/3f6f1a9e5ede6212425f3b36b136216e
# #       It also relies on a hack described in https://trac.ffmpeg.org/ticket/6431#comment:7 to make glibc dynamic still.
# #       Long story short, you need to edit your ffmepg's configure script to avoid failures on libm and libdl.
# #         in function probe_cc, replace the _flags_filter=echo line to: _flags_filter='filter_out -lm|-ldl'

if [[ ! -n "$RepositoryName" ]]; then
    if [[ -n "$GITHUB_REPOSITORY" ]]; then
        RepositoryName="$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f 2 )"
    else
        RepositoryName="cspace"
    fi
fi


#install required things from apt
installLibs(){
echo "Installing prerequisites"

sudo apt-get -y --force-yes install gcc-4.8 c++-4.8 \
  autoconf automake build-essential libfreetype6-dev libgpac-dev \
  libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texi2html zlib1g-dev libvpx-dev \
  libharfbuzz-dev libfontconfig-dev   || exit 1
  

}

installCUDA(){

wget https://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux.run \
  -O /tmp/cuda-7-5.run   && \
chmod a+x /tmp/cuda-7-5.run  && \

cd /tmp && \
mkdir -p /tmp/cuda-extract && \
./cuda-7-5.run --tar mxvf --directory ./cuda-extract && \
sudo cp /tmp/cuda-extract/InstallUtils.pm /usr/lib/x86_64-linux-gnu/perl-base && \
sudo /tmp/cuda-7-5.run --silent --toolkit --samples --override  || return 1
export PATH=$PATH:/usr/local/cuda-7.5/bin
export LD_LIBRARY_PATH=/usr/local/cuda-7.5/lib64:$LD_LIBRARY_PATH

}


#Install nvidia SDK
installSDK(){
cd ~/ffmpeg_sources
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git  && \
cd nv-codec-headers  && \
git checkout old/sdk/8.0  && \
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
cd ~/ffmpeg_sources  
wget https://github.com/mstorsjo/fdk-aac/archive/refs/tags/v0.1.6.zip -O fdk-aac-0.1.6.zip && \
unzip -o fdk-aac-0.1.6.zip  && \
cd fdk-aac-0.1.6 && \
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
--disable-docs --disable-tools --disable-unit-tests \
--cpu=native --as=nasm --enable-static --disable-shared && \
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
git checkout release/3.4 && \
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
  --enable-nvenc \
  --enable-libfreetype  \
  && \
PATH="$HOME/bin:$PATH" make -j$(nproc)   && \
make -j$(nproc) install
# make -j$(nproc) distclean
hash -r
}

#The process
cd ~
mkdir -p ffmpeg_sources
installLibs || exit 1

/workspaces/$RepositoryName/bin/gcc-alternative 4.8 || exit 1
installCUDA || exit
installSDK || exit 1
compileNasm || exit 1
compileLibX264 || exit 1
compileLibMP3Lame || exit 1
compileLibfdkcc || exit 1
compileLibOpus || exit 1

/workspaces/$RepositoryName/bin/gcc-alternative 7 || exit 1
compileLibPvx || exit 1

/workspaces/$RepositoryName/bin/gcc-alternative 4.8 || exit 1
compileFfmpeg || exit 1
echo "Complete!"