# kernel-builder
### fork this repository and add your token in repository setting
copy from
[linux-surface/aarch64-packages](https://github.com/linux-surface/aarch64-packages)
## This repository is for storing and automatically building  ArchlinuxARM packages by qcom platform
##  Trust Repository
import my signing key:
```
sudo pacman-key --recv-keys F60FD4C6D426DAB6
sudo pacman-key --lsign F60FD4C6D426DAB6
```
add the following session in your `/etc/pacman.conf`:
```
[qcom]
Server = https://github.com/silime/ArchLinux-Packages/releases/download/$arch
#Server = https://github.com/silime/ArchLinux-Packages/releases/latest/download/ #daily
```
