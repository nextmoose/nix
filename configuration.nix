{ config, pkgs, ... } : let
    kludge = {
        at = pkgs.stdenv.mkDerivation {
	    name = "at" ;
	    src = ./. ;
	    buildInputs = [ pkgs.makeWrapper ] ;
	    installPhase = "makeWrapper /run/wrappers/bin/at $out/bin/at" ;
	} ;
    } ;
    utils = {
        name-it = named : builtins.listToAttrs ( builtins.map ( name : { name = name ; value = builtins.getAttr name named name ; } ) ( builtins.attrNames named ) ) ;
        sh-derivation = name : sets : dependencies : let
	    upper-case = string : builtins.replaceStrings [ "-" "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" ] [ "_" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" ] string ;
	    s = sets {
	        literal = name : value : "--run \"export ${ upper-case name}=${ builtins.replaceStrings [ "\"" ] [ "\\\"" ] ( builtins.toString value ) }\"" ;
	    } ;
	in
	pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./public/scripts + ("/" + name) ;
	    buildInputs = [ pkgs.coreutils pkgs.makeWrapper ] ;
	    installPhase = ''
	        mkdir $out &&
		    cp --recursive . $out/src &&
		    if [ -f $out/src/${ name }.sh ]
		    then
		        chmod 0500 $out/src/${ name }.sh &&
			    makeWrapper $out/src/${ name }.sh $out/bin/${ name } ${ builtins.concatStringsSep " " s }
		    fi
	    '' ;
	} ;
	structure = structures-dir : constructor-program : options : derivations.structure structures-dir constructor-program derivations.at options ;
    } ;
    derivations = utils.name-it {
        at = name : utils.sh-derivation name ( setters : [ ] ) [ pkgs.coreutils ] ;
        destructor = name : structures-dir : utils.sh-derivation name ( setters :  [ ( setters.literal "STRUCTURES_DIR" structures-dir ) ] ) [ pkgs.coreutils pkgs.utillinux ] ;
        foobar = name : utils.sh-derivation name ( setters : [ ( setters.literal "UUID" "59aeb05f-ae75-49de-a085-850638700e95" ) ] ) [ pkgs.coreutils ] ;
	post-commit = name : utils.sh-derivation name ( setters : [ ( setters.literal "REMOTE" "origin" ) ] ) [ pkgs.coreutils pkgs.git ] ;
	rebuild-nixos = name : utils.sh-derivation name ( setters : [ ( setters.literal "UUID" "59aeb05f-ae75-49de-a085-850638700e95" ) ] ) [ pkgs.coreutils pkgs.gnugrep pkgs.mktemp pkgs.rsync pkgs.systemd ] ;
	structure = name : structures-dir : constructor-program : at : { cleaner-program ? "${ pkgs.coreutils }/bin/true" , salt-program ? "${ pkgs.coreutils }/bin/true" , seconds ? 60 } : utils.sh-derivation name ( setters : [ ( setters.literal "STRUCTURES_DIR" structures-dir ) ( setters.literal "CONSTRUCTORS_PROGRAM" constructor-program ) ( setters.literal "CLEANER_PROGRAM" cleaner-program ) ( setters.literal "SALT_PROGRAM" salt-program ) ( setters.literal "SECONDS" seconds ) ] ) [ at pkgs.coreutils pkgs.utillinux ] ;
    } ;
    structures = structures-dir : {
        foobar = utils.structure structures-dir "${ derivations.foobar }/bin/foobar" { cleaner-program = "${ pkgs.coreutils }/bin/true" ; salt-program = "${ pkgs.coreutils }/bin/true" ; seconds = 60 * 60 ; } ;
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
    services = {
        atd = {
	    allowEveryone = true ;
	    enable = true ;
	} ;
	sshd.enable = true ;
        xserver = {
            enable = true ;
            displayManager.lightdm.enable = true ;
            desktopManager.lxqt.enable = true ;
            videoDrivers = [ "fbdev" ] ;
        } ;
    } ;
    system.stateVersion = "20.03" ;
    users.users.user = {
        isNormalUser = true ;
        extraGroups = [ "wheel" "atd" ] ;
        passwordFile = "/etc/nixos/password.asc" ;
        packages = [
#	    pkgs.chromium
	    pkgs.git
	    derivations.rebuild-nixos
	    pkgs.emacs
	    derivations.foobar
	    derivations.post-commit
	    ( ( structures "/home/user/structures" ).foobar )
        ] ;
    } ;
}

