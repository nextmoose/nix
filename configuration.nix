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
    system.stateVersion = "20.03" ;
    users.users.user = {
        isNormalUser = true ;
        extraGroups = [ "wheel" ] ;
        passwordFile = "/etc/nixos/password.asc" ;
        packages = [ pkgs.git rebuild-nixos ] ;
    } ;
}

