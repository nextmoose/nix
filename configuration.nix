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
    imports = [ ./hardware-configuration.nix ] ;
    networking = {
        interfaces = {
            eth0.useDHCP = true ;
            wlan0.useDHCP = true ;
        } ;
        useDHCP = false ;
        wireless = {
            enable = true ;
            networks = import ./private/networks.nix ;
        } ;
    } ;
#    nixpkgs.config.allowUnsupportedSystem = true ;
#    nixpkgs.config.allowUnsupportedSystems = true ;
    services.xserver = {
        autorun = false ;
        desktopManager.xterm.enable = true ;
#        displayManager = {
#            defaultSession = "none+i3" ;
#            defaultSession = "none+awesome" ;
#            defaultSession = "none+bspwm" ;
#            defaultSession = "none+dwm" ;
#            defaultSession = "none+evilwm" ;
#            defaultSession = "none+exwm" ;
#            sddm.enable = true ;
#            gdm.enable = true ;
#            lightdm.enable = true ;
#        } ;
#        enable = true ;
#        layout = "us" ;
#        windowManager.exwm.enable = true ;
#        windowManager.evilwm.enable = true ;
#        windowManager.dwm.enable = true ;
#        windowManager.bspwm = {
#            enable = true ;
#        } ;
#        windowManager.awesome = {
#            enable = true ;
#        } ;
#        windowManager.i3 = {
#            enable = true ;
#        } ;
    } ;
    system.stateVersion = "20.03" ;
    users.users.user = {
        isNormalUser = true ;
        extraGroups = [ "wheel" ] ;
        passwordFile = "/etc/nixos/password.asc" ;
        packages = [ pkgs.git rebuild-nixos ] ;
    } ;
}

