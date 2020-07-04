# NixOS for Raspberry Pi 4

## Introduction

I have installed NixOS on Raspberry Pi 4.
To a large extent, I followed the instructions in [NixOS for Raspberry Pi 4](https://lunar.computer/posts/nixos-image-raspberry-pi-4/)
but I found that things did not exactly "work out of the box" for me.
This is a documentation of the steps that I took.

## Requirements

1. An SD card reader/writer
2. a computer with wget, bunzip2, and dd
3. a raspberry pi
4. a USB keyboard
5. a monitor
6. a micro HDMI cable
7. a power supply
8. a SD card

## Procedure
1. Hook up the pi to the keyboard and monitor.
2. Download [the image](https://data.lunar.computer/nixos-sd-image-20.03pre206632.b0bbacb5213-aarch64-linux.img.bz2) to your computer.  Thank you [Lunar Computer](https://lunar.computer/about/) for providing the base image and for providing the base of these steps.  If I have seen farther than others, it is by standing on the shoulders of giants.
3. Flash your SD card.  I put the card in the reader/writer and plug it into my computer and use this command `bunzip2 --stdout ~/Downloads/nixos-sd-image-20.03pre206632.b0bbacb5213-aarch64-linux.img.bz2 | sudo dd of=/dev/sda`
`.  Let us assume that you downloaded the previously described image into your Downloads folder and your computer recognizes your card as '/dev/sda'.  In my experience this takes about 20 minutes.
4. Eject your SD card from your computer.  Put it in your PI.
5. Power up your pi.
6. Wait for it to boot up.  Should not take too long.
7. You should be logged in as 'nixos' user.  Execute `sudo su --login` to act as root.
8. Execute `systemctl stop wpa_supplicant.service && wpa_supplicant -B -i wlan0 -c <(wpa_passphrase "${YOUR_WIFI_SSID}" "${YOUR_WIFI_PASSWORD}") && sleep 10s && ping -c 10 8.8.8.8` to get your wifi connectivity.
9. I don't know if you need to execute this but do it anyway: `systemctl restart nix-daemon.service`.
10. Execute `date --set "Sat 04 Jul 2020 09:51:16 AM EDT"`.  You can get the current date by executing `date` on your computer.
11. Thanks to user [Gaelen](https://github.com/Gaelan) for this [helpful comment](https://github.com/NixOS/nixpkgs/issues/63720#issuecomment-628858247).  You need to execute as root `mkdir /boot && sudo mount /dev/mmcblk0p1 /boot && nixos-generate-config`.
12. This will generate two files in the previously empty '/etc/nixos' directory.  You need to edit '/etc/nixos/configuration.nix' with these three things in mind.  You can edit the file by running `nixos-rebuild edit`
    1. boot loader
       1. boot.loader.grub.enable = false;
       2. boot.loader.raspberryPi.enable = true;
       3. boot.loader.raspberryPi.version = 4;
       4. boot.kernelPackages = pkgs.linuxPackages_rpi4;
    2. enable wireless connectivity by uncommenting out this line `networking.wireless.enable`
    3. make sure you have some way to login before rebooting
       1. I uncomment out the users stanza, change jane to user, and add the line `passwordFile = "/etc/nixos/password.asc"`
13. As root, `echo ${YOUR_NEW_PASSWORD} | mkpasswd --stdin -m sha-512 > /etc/nixos/password.asc`
14. As root, run `nixos-rebuild build`.  This should take about 20 minutes.  This builds the derivations.  This does not change anything.
15. As root, run `nixos-rebuild test`.  This uses the new configuration but does not change it in the boot.  This changes your PI for the current boot and after rebooting no changes will persist.
16. As root, run `nixos-rebuild switch`.  This should be very fast (because you have done the heavy lifting in the previous step).  I believe this will error.
17. As root, run `nixos-rebuild switch` again.  Is this necessary, I don't know.  Please experiment and find out for me.  It should not error the second time.  This changes the boot.  After this, your changes should be persisted between boots.
18. As root, reboot the PI.
19. Wait for the pi to boot up (should not take long).
20. Log in as user and with ${YOUR_NEW_PASSWORD}.
22. Execute `sudo su --login` to get full root powers.
22. Execute `systemctl stop wpa_supplicant.service && wpa_supplicant -B -i wlan0 -c <(wpa_passphrase "${YOUR_WIFI_SSID}" "${YOUR_WIFI_PASSWORD}") && sleep 10s && ping -c 10 8.8.8.8` to start wifi.

## Discussion
This is perhaps an overly prescriptive summary of the steps I took to put nixos on my Raspberry Pi 4 card.
This is probably not the best way.
You might not need all the steps.

I think Lunar Computer image has two partitions:  FIRMWARE and NIXOS.
FIRMWARE is just the boot partition.
NIXOS has the interesting stuff.

When you boot off the image, your PI's clock will be set to January 1, 1970.
This seems to cause problems with building derivations (not sure why).

The PI probably would be hooked up to the internet if you plugged it in, but I do not have that capability so I have to run those command to hook it up to wifi.
I have a little sleep because it seems to take a few seconds to actually start working.
The ping is just a sanity check to verify you actually have wifi internet.
It is better to debug it early in the process than later when your builds fail.

I very much appreciate Gaelen's comment.
Before I read his comment, I was modifying the configuration.nix file to my liking, installing, and rebooting to the very same unmodified configuration I started with.
The important part is that you must mount the boot image to boot - which seems obvious in retrospect; but looking prospectively it was not obvious at all.
If you go through the steps without this, the system will just create a boot directory which it will ignore on reboot.
So everything will look correct, but not work.

I recommend that you make baby-step, proof of concept, minimal changes to '/etc/nixos/configuration.nix'.
Once you prove that the system works, you can make your earth shattering changes.
The three changes I recommend:
1. Fix the boot loader (as shown by Gaelen).
2. Enable wireless connectivity (because I need wifi ... maybe you don't.)
3. Create a way to login.

I like to run `nixos-rebuild build && nixos-rebuild test && nixos-rebuild switch`.
You do not need to do this, but I like to because it seems this process is error prone and if you split a big task into two smaller tasks it is easier to see where things went wrong.
If you run `nixos-rebuild switch` alone it will do the building and testing.
However, if you run `nixos-rebuild build` and it fails then obviously the other two commands would have failed and you need to fix whatever is wrong.
If you run `nixos-rebuild test` and you do not like something about the configuration (for example, you forget to enable wireless connectivity) or you locked yourself out; then you can just reboot and everything will be back as it was before.
If you run `nixos-rebuild switch && reboot` but you do not like the results, you might have to repeat this entire process starting with reflashing the drive.  If you are locked out, I do not know any other way.
