{ config, pkgs, ... } : let
    utils = {
        name-it = named : builtins.listToAttrs ( builtins.map ( name : { name = name ; value = builtins.getAttr name named name ; } ) ( builtins.attrNames named ) ) ;
        sh-derivation = name : sets : dependencies : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./public/scripts + ("/" + name) ;
	    buildInputs = [ pkgs.coreutils pkgs.makeWrapper ] ;
	    installPhase = ''
	        mkdir $out &&
		    cp --recursive . $out/src &&
		    if [ -f $out/src/${ name }.sh ]
		    then
		        chmod 0500 $out/src/${ name }.sh &&
		            makeWrapper $out/src/${ name }.sh $out/bin/${ name } ${ builtins.concatStringsSep " " ( builtins.map ( name : "--run \"export ${ utils.upper-case name }=${ builtins.getAttr name sets } &&\"" ) ( builtins.attrNames sets ) ) } --set PATH "${ pkgs.lib.makeBinPath dependencies }"
		    fi
	    '' ;
	} ;
	upper-case = string : builtins.replaceStrings [ "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" ] [ "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" ] string ;
    } ;
    derivations = utils.name-it {
        foobar = name : utils.sh-derivation name { uuid = "59aeb05f-ae75-49de-a085-850638700e95" ; } [ pkgs.coreutils ] ;
	post-commit = name : utils.sh-derivation name { remote = "origin" ; } [ pkgs.coreutils pkgs.git ] ;
	rebuild-nixos = name : utils.sh-derivation name { uuid = "59aeb05f-ae75-49de-a085-850638700e95" ; } [ pkgs.coreutils pkgs.gnugrep pkgs.mktemp pkgs.rsync pkgs.systemd ] ;
	standard-structure-dates = name : utils.sh-derivation name { } [ pkgs.coreutils ] ;
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
        packages = [ pkgs.git derivations.rebuild-nixos pkgs.emacs derivations.foobar derivations.post-commit derivations.standard-structure-dates ] ;
    } ;
}

