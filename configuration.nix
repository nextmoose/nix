{ config, pkgs, ... } : let
    literal = value : name : "--run \"export ${ utils.upper-case name }=${ builtins.replaceStrings [ "\"" ] [ "\\\"" ] ( builtins.toString value ) }\"" ;
    structure-dir = value : name : "--run \"export ${ utils.upper-case name }=${ builtins.replaceStrings [ "\"" "\$" ] [ "\\\"" "\\\$" ] ( builtins.concatStringsSep "" [ "\$( " ( builtins.toString value ) "/bin/structure )" ] ) }\"" ;
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
			    makeWrapper $out/src/${ name }.sh $out/bin/${ name } ${ builtins.concatStringsSep " " ( builtins.map ( name : ( builtins.getAttr name sets ) name ) ( builtins.attrNames sets ) ) } --run "export PATH=${ pkgs.lib.makeBinPath dependencies }"
		    fi
	    '' ;
	} ;
	structure = structures-dir : constructor-program : options : derivations.structure structures-dir constructor-program derivations.destructor options ;
	upper-case = string : builtins.replaceStrings [ "-" "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" ] [ "_" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" ] string ;
    } ;
    derivations = utils.name-it {
	destructor = name : utils.sh-derivation name { } [ pkgs.coreutils ] ;
	dot-gnupg = name : gpg-private-keys : gpg-ownertrust : gpg2-private-keys : gpg2-ownertrust : utils.sh-derivation name { gpg-private-keys = gpg-private-keys ; gpg-ownertrust = gpg-ownertrust ; gpg2-private-keys = gpg2-private-keys ; gpg2-ownertrust = gpg2-ownertrust ; } [ pkgs.coreutils pkgs.gnupg ] ;
	fetchFromGithub = name : owner : repo : rev : sha256 : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = pkgs.fetchFromGitHub {
	        owner = owner ;
		repo = repo ;
		rev = rev ;
		sha256 = sha256 ;
	    } ;
	    buildInputs = [ pkgs.coreutils ] ;
	    installPhase = "cp --recursive . $out" ;
	} ;
        foo = name : uuid : utils.sh-derivation name { uuid = uuid ; } [ pkgs.coreutils ] ;
	foobar = name : foo : utils.sh-derivation name { foo = foo ; } [ pkgs.coreutils ] ;
	pass = name : executable-name : dot-gnupg : password-store-dir : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./empty ;
	    buildInputs = [ pkgs.makeWrapper ] ;
	    installPhase = "makeWrapper ${ pkgs.pass }/bin/pass $out/bin/${ executable-name } ${ dot-gnupg "dot-gnupg" } ${ password-store-dir "password-store-dir" } --run 'export PASSWORD_STORE_GPG_OPTS=\"--batch --pinentry loopback --homedir \$DOT_GNUPG\"' --set PATH ${ pkgs.lib.makeBinPath [ pkgs.pinentry pkgs.pinentry-qt ] }" ;
	} ;
	post-commit = name : remote : utils.sh-derivation name { remote = remote ; } [ pkgs.coreutils pkgs.git ] ;
	rebuild-nixos = name : utils.sh-derivation name { } [ pkgs.coreutils pkgs.gnugrep pkgs.mktemp pkgs.rsync pkgs.systemd ] ;
	structure = name : structures-dir : constructor-program : destructor : { cleaner-program ? "${ pkgs.coreutils }/bin/true" , salt-program ? "${ pkgs.coreutils }/bin/true" , seconds ? 60 * 60 } : utils.sh-derivation name { structures-dir = literal structures-dir ; constructor-program = literal constructor-program ; cleaner-program = literal cleaner-program ; salt-program = literal salt-program ; seconds = literal seconds ; destructor-program = literal "${ destructor }/bin/destructor" ; } [ pkgs.coreutils pkgs.utillinux ] ;
    } ;
    structures = structures-dir : {
        dot-gnupg = gpg-private-keys : gpg-ownertrust : gpg2-private-keys : gpg2-ownertrust : utils.structure structures-dir "${ derivations.dot-gnupg gpg-private-keys gpg-ownertrust gpg2-private-keys gpg2-ownertrust }/bin/dot-gnupg" { } ;
        foo = uuid : utils.structure structures-dir "${ derivations.foo uuid }/bin/foo" { } ;
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
	    pkgs.firefox
	    pkgs.git
	    pkgs.gnupg
	    pkgs.gpgme
	    pkgs.keychain
#	    pkgs.pinentry
#	    pkgs.pinentry-qt
#	    pkgs.pinentry-emacs pkgs.pinentry-gnome pkgs.pinentry-gtk2
	    # pkgs.pinentry_mac
	    pkgs.signing-party
	    pkgs.pinentry-curses
	    derivations.rebuild-nixos
	    pkgs.emacs
	    ( derivations.foo ( literal "b59c8073-29be-4425-966c-e215101e3448" ) )
	    ( derivations.foobar ( structure-dir ( ( structures"/home/user/structures" ).foo ( literal "b2b48732-9547-4e14-bb8f-31fed11cc8d6" ) ) ) )
	    ( derivations.post-commit ( literal "origin" ) )
#	    ( ( structures "/home/user/structures" ).foo ( literal "59dab5e4-85d1-4480-9aed-abd45142d92e" ) )
	    ( ( structures "/home/user/structures" ).dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) )
	    ( derivations.pass "system-secrets" ( structure-dir ( ( structures "/home/user/structures" ).dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGithub "nextmoose" "secrets" "7c044d920affadca7e66458a7560d8d40f9272ec" "1xnja2sc704v0qz94k9grh06aj296lmbgjl7vmwpvrgzg40bn25l" ) ) )
        ] ;
    } ;
}

