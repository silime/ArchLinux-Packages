#!/usr/bin/env bash

VERSION=$(grep 'Kernel Configuration' < config | awk '{print $3}')

# add deb-src to sources.list
sed -i "/deb-src/s/# //g" /etc/apt/sources.list

# install dep
sudo apt update
sudo apt install -y wget 
sudo apt install -y build-essential openssl pkg-config libssl-dev libncurses5-dev pkg-config minizip libelf-dev flex bison  libc6-dev libidn11-dev rsync bc liblz4-tool  
sudo apt install -y gcc-aarch64-linux-gnu dpkg-dev dpkg git
sudo apt build-dep -y linux

# change dir to workplace
cd "${GITHUB_WORKSPACE}" || exit

# download kernel source and patch
git clone -b sdm845/5.19-dev https://gitlab.com/sdm845-mainline/linux.git --depth=1
cd linux  || exit

# generate .config
echo "CONFIG_DRM_PANEL_JDI_NT35596S=y" >> arch/arm64/configs/sdm845.config
echo "Add mix2s.patch"
git am ../mix2s.patch
make ARCH=arm64 defconfig sdm845.config



# build deb packages
make -j$(nproc) ARCH=arm64 KBUILD_DEBARCH=arm64 KDEB_CHANGELOG_DIST=mobile CROSS_COMPILE=aarch64-linux-gnu- deb-pkg
# This will generate several deb files in ../

# move deb packages to artifact dir
cd ..
mkdir "artifact"
mkdir artifact/dtb
cp linux/arch/arm64/boot/dts/qcom/sdm845-*.dtb artifact/dtb/
mv ./*.deb artifact/
