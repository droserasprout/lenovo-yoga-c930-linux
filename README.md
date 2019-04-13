# lenovo-yoga-c930-linux
Various fixes to provide full hardware support of Lenovo Yoga C930 on Linux

All solutions was tested with Fedora Workstation 29 (kernel 5.0.6-200.fc29.x86_64) but should wokk with any Linux distribution. 

### Fix sound (enable subwoofer)
* Install `alsa-tools-gui` package (`alsa-utils` in some distributions)
* Run `hdajackretask`
* Set "Show unconnected pins" tick in "Options"
* Set pin with ID `0x17` to "Override" with "Dock Headphone"
* Click "Install boot override" and enter sudo password
* Reboot

You can also apply fix immediately but most likely it will fail due to `pulseaudio` autospawn. If you want to apply fix without rebooting you need to:
* Append `autospawn = no` to `/etc/pulse/client.conf`
* Run `pulseaudio -k`
* Hit "Apply now" in hdajackretask window
* Revert first step, run pulseaudio

### Fix Wi-Fi
There's [a bug](https://github.com/torvalds/linux/commit/ce363c2bcb2303e7fad3a79398db739c6995141b) in `ideapad-laptop` kernel module preventing wi-fi from being enabled on some models (including C930) which lack physical wi-fi switch. The solution is to prevent this module from being loaded on boot:
```
# sudo modprobe -r ideapad-laptop`
# echo "blacklist ideapad-laptop" | sudo tee -a /etc/modprobe.d/blacklist.conf
```

### Fix battery firmware (optional)

I have wiped Windows partitions and installed Fedora right after purchasing this laptop and ensuring latest BIOS version is installed. After some time I've found out that battery stucked on `99% Charging` and never goes `100% Full`. If you're facing the same issue first of all: **DO NOT PANIC**. At least before recharging battery 3-5 full cycles. In my case this helped, the problem is gone.

But there're many similar problems with Lenovo batteries firmware in general ([evidence from year 2014!](http://code.jasonbhill.com/linux/faulty-firmware-in-lenovo-batteries/)) and Lenovo offers [Battery Firmware Update](https://pcsupport.lenovo.com/us/en/products/LAPTOPS-AND-NETBOOKS/YOGA-SERIES/YOGA-C930-13IKB/downloads/DS505955) for C930 too to fix an issue "where the battery capacity abnormal loss then the battery life might be reduced". In my case battery firmware was already updated and some recharge cycles have fixed the problem. But if you're facing some battery issues or just want to be sure about this, here's a guide to update battery firmware without Windows installed:

* Find some WinPE ISO based on latest Windows version. Consider using [MediCat DVD](https://gbatemp.net/threads/medicat-dvd-a-multiboot-linux-dvd.361577/) or [Win10PESE](https://toolslib.net/downloads/viewdownload/255-winpese-x64/).
* Burn ISO to USB flash drive with ```woeusb```. Remember you can't make Windows bootable drives with plain `dd`.
* Mount resulting partition. Create a directory for downloaded drivers.
* Find out your battery vendor:
```
$ upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep vendor
  vendor:               Celxpert
```
* Download [Energy Manager Driver](https://pcsupport.lenovo.com/us/en/products/LAPTOPS-AND-NETBOOKS/YOGA-SERIES/YOGA-C930-13IKB/downloads/DS503661) (file named `wwe00aae.exe`) and copy it in directory created on a flash drive.
* Download [Battery Firmware Update](https://pcsupport.lenovo.com/us/en/products/LAPTOPS-AND-NETBOOKS/YOGA-SERIES/YOGA-C930-13IKB/downloads/DS505955) matching your battery vendor. Looks like a ZIP file, right? But it's not.
```
$ file yogac930_bat_cpt_201812.zip 
yogac930_bat_cpt_201812.zip: RAR archive data, v5
```
Nice trick, Lenovo! So, `unrar` this archive
`$ unrar x yogac930_bat_cpt_201812.zip . -v`
and copy resulting executable to the flash drive.
* Poweroff laptop, press power button with holded `Fn` key. Choose "Boot menu", load from WinPE partition.
* Install Energy Manager Driver (replace C: with B: in installation paths when needed). Then install Battery Firmware Update.
* Done!

### Fix fingerprint sensor
Workinonit
