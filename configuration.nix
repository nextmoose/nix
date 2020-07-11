{ config, pkgs, ... } : let
    literal = value : name : "--run \"export ${ utils.upper-case name }=${ builtins.replaceStrings [ "\"" ] [ "\\\"" ] ( builtins.toString value ) }\"" ;
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
			    makeWrapper $out/src/${ name }.sh $out/bin/${ name } ${ builtins.concatStringsSep " " ( builtins.map ( name : ( builtins.getAttr name sets ) name ) ( builtins.attrNames sets ) ) }
		    fi
	    '' ;
	} ;
	structure = structures-dir : constructor-program : options : derivations.structure structures-dir constructor-program derivations.at options ;
	upper-case = string : builtins.replaceStrings [ "-" "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" ] [ "_" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" ] string ;
    } ;
    derivations = utils.name-it {
        at = name : utils.sh-derivation name { } [ pkgs.coreutils ] ;
        foobar = name : uuid : utils.sh-derivation name { uuid = uuid ; } [ pkgs.coreutils ] ;
	post-commit = name : remote : utils.sh-derivation name { remote = remote ; } [ pkgs.coreutils pkgs.git ] ;
	rebuild-nixos = name : utils.sh-derivation name { } [ pkgs.coreutils pkgs.gnugrep pkgs.mktemp pkgs.rsync pkgs.systemd ] ;
	structure = name : structures-dir : constructor-program : at : { cleaner-program ? "${ pkgs.coreutils }/bin/true" , salt-program ? "${ pkgs.coreutils }/bin/true" , seconds ? 60 } : utils.sh-derivation name { structures-dir = literal structures-dir ; constructor-program = literal constructor-program ; cleaner-program = literal cleaner-program ; salt-program = literal salt-program ; } [ at pkgs.coreutils pkgs.utillinux ] ;
    } ;
    structures = structures-dir : {
        foobar = uuid : utils.structure structures-dir "${ derivations.foobar uuid }/bin/foobar" { } ;
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
	    pkgs.git
	    derivations.rebuild-nixos
	    pkgs.emacs
	    ( derivations.foobar ( literal "b59c8073-29be-4425-966c-e215101e3448" ) )
	    ( derivations.post-commit ( literal "origin" ) )
	    ( ( structures "/home/user/structures" ).foobar ( literal "59dab5e4-85d1-4480-9aed-abd45142d92e" ) )
        ] ;
    } ;
}

