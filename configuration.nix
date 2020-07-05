{ config, pkgs, ... } : let
rebuild-nixos = pkgs.stdenv.mkDerivation {
    name = "rebuild-nixos" ;
    src = ./public/scripts/rebuild-nixos ;
    buildInputs = [ pkgs.coreutils pkgs.makeWrapper ] ;
    installPhase = ''
        mkdir $out &&
            cp --recursive . $out/src &&
            chmod 0500 $out/src/rebuild-nixos.sh &&
            makeWrapper $out/src/rebuild-nixos.sh $out/bin/rebuild-nixos --set PATH "${ pkgs.lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep pkgs.mktemp pkgs.rsync pkgs.systemd ] }"
    '' ;
} ;
in {
    boot = {
        kernelPackages = pkgs.linuxPackages_rpi4 ;
        loader = {
            grub = {
                enable = false ;
                version = 2 ;
            } ;
            raspberryPi = {
                enable = true ;
                version = 4 ;
            } ;
        } ;
    } ;
    imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-raspberrypi4.nix> ] ;
#    imports = [ ./hardware-configuration.nix ] ;
    networking = {
        interfaces = {
            eth0.useDHCP = true ;
            wlan0.useDHCP = true ;
        } ;
        useDHCP = false ;
        wireless = {
#            enable = false ;
            enable = true ;
            networks = import ./private/networks.nix ;
        } ;
    } ;
    services.xserver = {
        enable = true ;
        displayManager.lightdm.enable = true ;
        desktopManager.lxqt.enable = true ;
        videoDrivers = [ "fbdev" ] ;
    } ;
    system.stateVersion = "20.03" ;
    users.users.user = {
        isNormalUser = true ;
        extraGroups = [ "wheel" ] ;
        passwordFile = "/etc/nixos/password.asc" ;
        packages = [ pkgs.git rebuild-nixos pkgs.emacs ] ;
    } ;
}

