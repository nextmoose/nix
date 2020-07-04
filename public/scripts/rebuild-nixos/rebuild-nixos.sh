#!/bin/sh

/run/wrappers/bin/sudo rsync --archive --delete --progress configuration.nix /etc/nixos/configuration.nix &&
/run/wrappers/bin/sudo rsync --archive --delete --progress private /etc/nixos/private &&
/run/wrappers/bin/sudo rsync --archive --delete --progress public /etc/nixos/public &&
time /run/wrappers/bin/sudo /run/current-system/sw/bin/nixos-rebuild build &&
time /run/wrappers/bin/sudo /run/current-system/sw/bin/nixos-rebuild test &&
time /run/wrappers/bin/sudo /run/current-system/sw/bin/nixos-rebuild switch &&
true
