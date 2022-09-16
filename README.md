# Linux on Lenovo Yoga C930

> “We do not support Linux. Please call Linux to resolve this issue.”

*Lenovo support, via [jasonbhill](http://code.jasonbhill.com/linux/faulty-firmware-in-lenovo-batteries/)*

## About

At this page you can find various notes about hardware support of Lenovo Yoga C930 on Linux. All solutions was tested with Fedora Workstation 29 but should work with any Linux distribution.

If your main question is "Should I buy this laptop for using with Linux now?" than answer is "No". Massive ACPI and Power Management issues, microphone, surround speakers and fingerprint sensor not working.

## Summary

* Minimum BIOS version: **8GCN32WW**
* Minimum kernel version: **5.1-rc1** (see [Older kernels](#older-kernels) otherwise)
* Latest tested kernel version: **5.1-rc6**

| Subsystem | Status | Notes |
|---------------------|---------------|---------------------------------------------------------------------------------------------|
| Internal storage | ✔️ Working |  |
| Graphics | ✔️ Working |  |
| Type-A port | ✔️ Working |  |
| Type-C port | ✔️ Working |  |
| Thunderbolt 3 | ⚠️ Not tested |  |
| Keyboard | ✔️ Working |  |
| Wi-Fi, Bluetooth | ✔️ Working | [fix for kernels older than 5.1-rc1](#older-kernels) |
| Speakers | ⚠️ Partially | [Fix needed](#speaker) for hinge soundbar, bottom speakers not working |
| Headphone plug | ✔️ Working | |
| Microphone | ✔️ Working | See [blog post for mic and speaker fix](https://gist.github.com/crojewsk/4e6382bfb0dbfaaf60513174211f29cb)|
| Power Management | ⚠️ Partially | critical suspend issues, see [notes](#power-management-issues)
| Touchscreen | ✔️ Working |  |
| Active pen | ✔️ Working | does not report battery level |
| Rotation sensor | ✔️ Working |  |
| Light sensor | ✔️ Working |  |
| Fingerprint sensor | ❌ Not working | you can track development progress [here](https://github.com/nmikhailov/Validity90) |
| HDMI output | ⚠️ Partially | Working on kernel 5.16, may work on lower versions as well  |
| HDMI audio output | ⚠️ Partially | Working on kernel 5.16, may work on lower versions as well |
| Webcam | ✔️ Working |  |

## Fixes

### Speaker

[This blog post](https://gist.github.com/crojewsk/4e6382bfb0dbfaaf60513174211f29cb) describes how to default to the proper soundcard driver for Intel skylake chips, such as the one in the Yoga C930. This will enable HDMI audio output, speaker output, and digital microphone input.

### Additional Speaker Hack

This laptop has 5.1 speaker configuration with only Front Left and Front Right working by default. This hack can enable another one (Front Center or LFE, not sure):

**NOTE:** This hack can make headphone sound quieter. Try setting pin `0x21` to "Override" with "Headphone" to resolve.

* Install `alsa-tools-gui` package (`alsa-utils` in some distributions)
* Run `hdajackretask`
* Set "Show unconnected pins" tick in "Options"
* Set pin with ID `0x17` to "Override" with "Dock Headphone"
* Click "Install boot override" and enter sudo password
* Reboot

You can also apply fix immediately but it will most likely fail due to soundcard is in use by `pulseaudio`. If you want to apply fix without rebooting you need to stop pulseaudio first.

It seems like to fix this issue either Lenovo should release BIOS update with correct pin mappings or some model definition should be added to snd-hda-intel module like it was done for another Lenovo laptops with surround sound. See [Lenovo Y530 example](https://ubuntuforums.org/showthread.php?t=1596068).

[Bug 203409 - Lenovo YOGA C930-13IKB (ALC298): internal mic and most of surround speakers not working](https://bugzilla.kernel.org/show_bug.cgi?id=203409)

## Notes
### Older kernels
Kernel versions prior to **5.1-rc1** have a bug in `ideapad-laptop` module preventing wireless interfaces from being enabled.
```
$ rfkill list
0: ideapad_wlan: Wireless LAN
	Soft blocked: no
	Hard blocked: yes
1: ideapad_bluetooth: Bluetooth
	Soft blocked: yes
	Hard blocked: yes
```
If your devices are hard blocked by rfkill there are two ways of dealing with this:

Recommended: cherrypick [this commit](https://github.com/torvalds/linux/commit/67133c6d99ef0d8917f764a9a70039b5e78d5e71) to desired branch and build a whole kernel or just `ideapad-laptop` module by yourself.

**TODO:** Guide how to build patched ideapad-laptop

Another solution is to prevent faulty module from being loaded on boot:

**WARNING: This could break some ACPI functionality! Use at your own risk!** 
```
# sudo modprobe -r ideapad-laptop`
# echo "blacklist ideapad-laptop" | sudo tee -a /etc/modprobe.d/blacklist.conf
```

### Power Management issues

#### S0 (s2idle) power state state battery drain

Our main troubleshooting guide: [How to achieve S0ix states in Linux](https://01.org/blogs/qwang59/2018/how-achieve-s0ix-states-linux)

> The S0ix state is entered only when the `low_power_idle_system_residency_us` counter increases during the S2idle low power state.

```
$ cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec
0
$ cat /sys/devices/system/cpu/cpuidle/low_power_idle_cpu_residency_us
0
```
So seems like S0ix is broken for now.

Fixed in kernels 5.3 and newer (not tested)

[Bug 203383 - Lenovo YOGA C930-13IKB unable to enter S0ix](https://bugzilla.kernel.org/show_bug.cgi?id=203383)

#### S3 (deep) power state not working

ACPI reports that system supports S3 state:
```
$ dmesg | grep S3
[    0.319612] ACPI: (supports S0 S3 S4 S5)
```
But as initially reported by user *kawb* [here](https://forums.lenovo.com/t5/Other-Linux-Discussions/Linux-compatibility-with-Yoga-C930/m-p/4350515/highlight/true#M12516) entering S3 state makes system completely unresponsive (black screen with no backlight, power LED on, fans on). The only way to escape is to **power cycle** laptop (poweroff with long power button press, **wait about 10 seconds**, press power button again).

Default  `mem_sleep` state is `s2idle`, so to force entering S3 we have to set `mem_sleep` to `deep`:
```
$ cat /sys/power/mem_sleep
[s2idle] deep
$ echo deep | sudo tee /sys/power/mem_sleep
deep
$ # WARNING: deadlock ahead!
$ systemctl suspend
```

#### ACPI: button: The lid device is not compliant to SW_LID

#### cycle_count (not supported)

### Fn lock

F1-F12 row behaviour can be changed in BIOS. 

### Conservation Mode

Conservation mode in some Lenovo laptops will stop the battery from charging above 60% to improve the lifespan of the battery.

Enable:
```
$ echo 1 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
```
Disable:
```
$ echo 0 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
```

**NOTE:** You will still see "Charging" state and estimated time to full while being in Conservation mode.

## FW update
### Battery firmware

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

## Links

* [Main thread at Lenovo forums](https://forums.lenovo.com/t5/Other-Linux-Discussions/Linux-compatibility-with-Yoga-C930/td-p/4267325)
* [Lenovo subreddit](https://www.reddit.com/r/Lenovo/)

### Power Management

* [System Sleep States](https://www.kernel.org/doc/html/v4.15/admin-guide/pm/sleep-states.html)
* [System Power Management Sleep States](https://www.kernel.org/doc/Documentation/power/states.txt)
* [TLP FAQ](https://linrunner.de/en/tlp/docs/tlp-faq.html)
* [(How to achieve S0ix states in Linux)](https://01.org/blogs/qwang59/2018/how-achieve-s0ix-states-linux)
* [Lenovo X1C6 / X1Y3 (2018): No deep sleep (S3)](https://bbs.archlinux.org/viewtopic.php?id=234913)
* [linux-surface-patches (may be related)](https://github.com/kitakar5525/linux-surface-patches)

### Misc

* https://github.com/NixOS/nixpkgs/issues/51037
* https://01.org/linuxgraphics/gfx-docs/drm/sound/hd-audio/models.html
* https://01.org/linuxgraphics/gfx-docs/drm/sound/hd-audio/notes.html
* https://git.alsa-project.org/?p=alsa.git;a=tree;f=hda-analyzer
