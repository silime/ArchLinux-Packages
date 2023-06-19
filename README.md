# kernel-builder
### fork this repository and add your token in repository setting
copy from
[linux-surface/aarch64-packages](https://github.com/linux-surface/aarch64-packages)
## sensors
### update firmware and install sensors package
```bash
libssc hexagonrpcd libqmi iio-sensor-proxy
```
modemmanager is broken, if you need to enable it, try to reinstall libqmi 
```bash
sudo pacman -S libqmi
```  