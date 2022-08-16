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
git clone -b sdm845/5.19-release https://gitlab.com/sdm845-mainline/linux.git --depth=1
cd linux  || exit

# add some patch
echo "Add MI8-dipper.patch"
git am ../MI8-dipper.patch
echo "supply: pmi8998_charger: drop in v5, fix slow charging patch"
git am ../41.patch
# add mix2s panel driver
# sed -i "s/^.*CONFIG_DRM_PANEL_JDI_NT35596S.*$/CONFIG_DRM_PANEL_JDI_NT35596S=y/" .config

# generate .config
make ARCH=arm64 defconfig sdm845.config

# build deb packages
make -j$(nproc) ARCH=arm64 KBUILD_DEBARCH=arm64 KDEB_CHANGELOG_DIST=mobile CROSS_COMPILE=aarch64-linux-gnu- deb-pkg
# This will generate several deb files in ../

# move deb packages to artifact dir
cd ..
mkdir "artifact"

cp linux/arch/arm64/boot/dts/qcom/sdm845-*.dtb artifact/
mv ./*.deb artifact/
