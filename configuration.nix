{ config, pkgs, ... } : let
    literal = value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : "--run \"export ${ utils.replace-strings "${ utils.upper-case name }=\"${ builtins.toString value }\"" }\"" ;
    } ;
    structure-dir = value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : "--run \"export ${ utils.replace-strings "${ utils.upper-case name }=\"$( ${ builtins.toString value } )\"" }\"" ;
    } ;
    utils = {
        name-it = named : builtins.listToAttrs ( builtins.map ( name : { name = name ; value = builtins.getAttr name named name ; } ) ( builtins.attrNames named ) ) ;
	replace-strings = string : builtins.replaceStrings [ "\"" "\$" ] [ "\\\"" "\\\$" ] string ;
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
			    makeWrapper $out/src/${ name }.sh $out/bin/${ name } ${ builtins.concatStringsSep " " ( builtins.map ( name : ( builtins.getAttr name sets ).export ( utils.upper-case name ) ) ( builtins.attrNames sets ) ) } --run "export STORE_DIR=$out" --run "export PATH=${ pkgs.lib.makeBinPath dependencies }"
		    fi
	    '' ;
	} ;
	structure = constructor-program : options : derivations.structure constructor-program derivations.destructor options ;
	upper-case = string : builtins.replaceStrings [ "-" "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" ] [ "_" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" ] string ;
    } ;
    derivations = utils.name-it {
	destructor = name : utils.sh-derivation name { } [ pkgs.coreutils ] ;
        foo = name : uuid : utils.sh-derivation name { uuid = uuid ; } [ pkgs.coreutils ] ;
	foobar = name : literal : dir : file : cat : utils.sh-derivation name { literal = literal ; dir = dir ; file = file ; cat = cat ; } [ pkgs.coreutils ] ;
	post-commit = name : remote : utils.sh-derivation name { remote = remote ; } [ pkgs.coreutils pkgs.git ] ;
	rebuild-nixos = name : utils.sh-derivation name { } [ pkgs.coreutils pkgs.gnugrep pkgs.rsync pkgs.systemd ] ;
	structure = name : constructor-program : destructor : { structures-dir ? "/home/user/structures" , cleaner-program ? "${ pkgs.coreutils }/bin/true" , salt-program ? "${ pkgs.coreutils }/bin/true" , seconds ? 60 * 60 } : utils.sh-derivation name { structures-dir = literal structures-dir ; constructor-program = literal constructor-program ; cleaner-program = literal cleaner-program ; salt-program = literal salt-program ; seconds = literal seconds ; destructor-program = literal "${ destructor }/bin/destructor" ; } [ pkgs.coreutils pkgs.utillinux ] ;
    } ;
    structures = {
        foo = uuid : utils.structure "${ derivations.foo uuid }/bin/foo" { } ;
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
	    pkgs.firefox
	    pkgs.git
	    pkgs.gnupg
	    pkgs.gpgme
	    pkgs.keychain
 	    pkgs.signing-party
	    pkgs.pinentry-curses
	    ( derivations.post-commit ( literal "origin" ) )
	    derivations.rebuild-nixos
	    ( derivations.foo ( literal "8ee9f204-e76f-4254-92fc-96ea94a0e88f" ) )
	    ( derivations.foobar ( literal "6c63a1d6-a6f3-42b0-8b1e-8364e0b0b4bf" ) ( structure-dir ( structures.foo ( literal "REPLACE ME" ) ) ) ( literal "a9def3f0-0f27-454b-8dec-e172d885499d" ) ( literal "a756baa1-8c7c-4625-9d3a-a829a7560232" ) )
        ] ;
    } ;
}

