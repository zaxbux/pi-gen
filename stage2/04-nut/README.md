# Network UPS Tools

There are a few adjustments to be made to improve stability.

Some situations to handle:

- UPS not connected on boot
  > This may occur during installation when the Pi is powered on before the UPS USB cable is attached.

  The units `nut-driver.service` and `nut-monitor.service` will fail to start.
  These units must be started once the UPS is connected.

- UPS disconnects
  > This may occur if the firmware has a bug, or if the user has disconnected the USB cable for some reason.

  The `nut-driver.service` unit should be restarted once a UPS is connected.

- Network not ready during boot
  > This may occur when power is restored and the Pi boots faster than upstream network hardware, resulting in delayed IP address assignment.

  Configure `upsd` to listen on all available interfaces.

## Links
- <https://networkupstools.org/docs/FAQ.html>
- <https://alioth-lists.debian.net/pipermail/nut-upsuser/2021-November/012582.html>
- <https://alioth-lists.debian.net/pipermail/nut-upsuser/2019-June/011451.html>
- <https://docs.technotim.live/posts/NUT-server-guide/>
- <https://wiki.debian.org/udev>

## udev

Writing udev rules: <http://www.reactivated.net/writing_udev_rules.html>

```
ACTION=="add|change", SUBSYSTEM=="usb|usb_device", SUBSYSTEMS=="usb|usb_device", ATTR{idVendor}=="09ae", ATTR{idProduct}=="2012", MODE="664", GROUP="nut", RUN+="/sbin/upsdrvctl stop; /sbin/upsdrvctl start"
```

```
SUBSYSTEM=="usb", ACTION=="add", ATTR{idVendor}=="0d9f", ATTR{idProduct}=="0004", RUN+="/usr/bin/systemctl restart nut-driver
```

Test: `udevadm trigger --subsystem-match=usb --action=change`
Monitor: `udevadm monitor --property`

## Cyber Power Systems

The firmware of this UPS brand seems to reset the USB interface after 20 seconds if a driver has not connected [^cyberpower_usb].

### Option 1

Decrease `pollinterval` value in `ups.conf`:

```
[ups]
	pollinterval = 15
```

Currently, `pollinterval` defaults to `30` seconds for the `usbhid-ups` driver.
There is also the `pollfreq` argument.

Source: <https://nmaggioni.xyz/2017/03/14/NUT-CyberPower-UPS/>

### Option 2

Add a udev rule to start services once the UPS is connected:

```
SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="0764", TAG+="systemd", ENV{SYSTEMD_WANTS}+="nut-server.service nut-monitor.service"
```

[^cyberpower_usb]: https://blog.cuviper.com/2012/11/23/cyberpower-fedora/