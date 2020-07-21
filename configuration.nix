{ config, pkgs, ... } : let
    literal = value : name : "--run \"export ${ utils.upper-case name }=${ utils.replace-strings ( builtins.toString value ) }\"" ;
    literals = values : name : "--add-flags ${ builtins.concatStringsSep " " ( builtins.map ( value : utils.replace-strings ( builtins.toString value ) ) values ) }" ;
    structure-dir = value : name : "--run \"export ${ utils.upper-case name }=${ utils.replace-strings ( builtins.concatStringsSep "" [ "\$( " ( builtins.toString value ) "/bin/structure )" ] ) }\"" ;
    structure-dirs = values : name : "--add-flags \"${ builtins.concatStringsSep " " ( builtins.map ( value : utils.replace-strings "$( ${ value }/bin/structure )" ) values ) }\"" ;
    structure-file = value : file-name : name : "--run \"export ${ utils.upper-case name }=${ utils.replace-strings ( builtins.concatStringsSep "" [ "\$( " ( builtins.toString value ) "/bin/structure )" "/" file-name ] ) }\"" ;
    structure-files = values : file-name : name : "--add-flags \"${ builtins.concatStringsSep " " ( builtins.map ( value : utils.replace-strings "$( ${ value }/bin/structure )/${ file-name }" ) values ) }\"" ;
    structure-cat = value : file-name : name : "--run \"export ${ utils.upper-case name }=${ utils.replace-strings ( builtins.concatStringsSep "" [ "\$( " pkgs.coreutils "/bin/cat " "\$( " ( builtins.toString value ) "/bin/structure )" "/" file-name " )" ] ) }\"" ;
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
			    echo makeWrapper $out/src/${ name }.sh $out/bin/${ name } ${ builtins.concatStringsSep " " ( builtins.map ( name : ( builtins.getAttr name sets ) name ) ( builtins.attrNames sets ) ) } --run "export STORE_DIR=$out" --run "export PATH=${ pkgs.lib.makeBinPath dependencies }"
			    makeWrapper $out/src/${ name }.sh $out/bin/${ name } ${ builtins.concatStringsSep " " ( builtins.map ( name : ( builtins.getAttr name sets ) name ) ( builtins.attrNames sets ) ) } --run "export STORE_DIR=$out" --run "export PATH=${ pkgs.lib.makeBinPath dependencies }"
		    fi
	    '' ;
	} ;
	structure = structures-dir : constructor-program : options : derivations.structure structures-dir constructor-program derivations.destructor options ;
	structures-dir = "/home/user/structures" ;
	system-secret = pass-name : file-name : structures.pass-file ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGithub "nextmoose" "secrets" "7c044d920affadca7e66458a7560d8d40f9272ec" "1xnja2sc704v0qz94k9grh06aj296lmbgjl7vmwpvrgzg40bn25l" ) ) ( literal pass-name ) ( literal file-name ) ;
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
	multiple-site-dot-ssh = name : configs : utils.sh-derivation name { configs = configs ; } [ pkgs.coreutils ] ;
	pass = name : executable-name : dot-gnupg : password-store-dir : extensions : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./empty ;
	    buildInputs = [ pkgs.coreutils pkgs.gnused pkgs.makeWrapper ] ;
	    installPhase = ''
	        makeWrapper ${ pkgs.pass }/bin/pass $out/bin/${ executable-name } ${ dot-gnupg "dot-gnupg" } ${ password-store-dir "password-store-dir" } --run "export PASSWORD_STORE_GPG_OPTS=\"--homedir \$DOT_GNUPG\"" --run "export PASSWORD_STORE_ENABLE_EXTENSIONS=true" --run "export PASSWORD_STORE_EXTENSIONS_DIR=\"$out/extensions\"" --set PATH ${ pkgs.lib.makeBinPath [ pkgs.pinentry pkgs.pinentry-qt ] }
		${ builtins.concatStringsSep " && " ( builtins.map ( name : "makeWrapper ${ ( builtins.getAttr name extensions ).program } $out/extensions/${ name }.bash" ) ( builtins.attrNames extensions ) ) }
		mkdir $out/completions
		PREFIX=$( echo ${ password-store-dir "prefix" } | cut --fields 3 --delimiter " " | cut --fields 2 --delimiter "=" )
		sed \
		    -e "s#_pass#_pass_$( basename $out )_#" \
		    -e "s# pass# ${ executable-name }#" \
		    -e "s#prefix=\".{PASSWORD_STORE_DIR:-.HOME/.password-store/\}\"#prefix=$PREFIX#" \
		    -e "w$out/completions.sh" \
		    ${ pkgs.pass }/share/bash-completion/completions/pass &&
		echo "PASSWORD_STORE_EXTENSION_COMMANDS=( ${ builtins.concatStringsSep " " ( builtins.attrNames extensions ) } )" >>  $out/completions.sh
	    '' ;
	} ;
	pass-file = name : dot-gnupg : password-store-dir : pass-name : file-name : utils.sh-derivation name { dot-gnupg = dot-gnupg ; password-store-dir = password-store-dir ; pass-name = pass-name ; file-name = file-name ; } [ pkgs.coreutils pkgs.pass ] ;
	pass-kludge-pinentry = name : utils.sh-derivation name { } [ pkgs.coreutils pkgs.gnupg ] ;
	personal-identification-number = name : file-name : digits : uuid : utils.sh-derivation name { file-name = file-name ; digits = digits ; uuid = uuid ; } [ pkgs.coreutils ] ;
	post-commit = name : remote : utils.sh-derivation name { remote = remote ; } [ pkgs.coreutils pkgs.git ] ;
	rebuild-nixos = name : utils.sh-derivation name { } [ pkgs.coreutils pkgs.gnugrep pkgs.mktemp pkgs.rsync pkgs.systemd ] ;
	single-site-dot-ssh = name : host : host-name : user : port : identity-file : user-known-hosts-file : utils.sh-derivation name { host = host ; host-name = host-name ; user = user ; port = port ; identity-file = identity-file ; user-known-hosts-file = user-known-hosts-file ; } [ pkgs.coreutils pkgs.gnused ] ;
	ssh = name : config : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./empty ;
	    buildInputs = [ pkgs.makeWrapper ] ;
	    installPhase = "makeWrapper ${ pkgs.openssh }/bin/ssh $out/bin/${ name } ${ config "config" } --add-flags \"-F \$CONFIG\"" ;
	} ;
	ssh-keygen = name : passphrase : utils.sh-derivation name { passphrase = passphrase ; } [ pkgs.openssh ] ;
	structure = name : structures-dir : constructor-program : destructor : { cleaner-program ? "${ pkgs.coreutils }/bin/true" , salt-program ? "${ pkgs.coreutils }/bin/true" , seconds ? 60 * 60 } : utils.sh-derivation name { structures-dir = literal structures-dir ; constructor-program = literal constructor-program ; cleaner-program = literal cleaner-program ; salt-program = literal salt-program ; seconds = literal seconds ; destructor-program = literal "${ destructor }/bin/destructor" ; } [ pkgs.coreutils pkgs.utillinux ] ;
    } ;
    structures = {
        dot-gnupg = gpg-private-keys : gpg-ownertrust : gpg2-private-keys : gpg2-ownertrust : utils.structure utils.structures-dir "${ derivations.dot-gnupg gpg-private-keys gpg-ownertrust gpg2-private-keys gpg2-ownertrust }/bin/dot-gnupg" { } ;
        foo = uuid : utils.structure utils.structures-dir "${ derivations.foo uuid }/bin/foo" { } ;
	multiple-site-dot-ssh = configs : utils.structure utils.structures-dir "${ derivations.multiple-site-dot-ssh configs }/bin/multiple-site-dot-ssh" { } ;
	pass-file = dot-gnupg : password-store-dir : pass-name : file-name : utils.structure utils.structures-dir "${ derivations.pass-file dot-gnupg password-store-dir pass-name file-name }/bin/pass-file" { } ;
	personal-identification-number = file-name : digits : uuid : utils.structure utils.structures-dir "${ derivations.personal-identification-number file-name digits uuid }/bin/personal-identification-number" { } ;
	single-site-dot-ssh = host : host-name : user : port : identity-file : user-known-hosts-file : utils.structure utils.structures-dir "${ derivations.single-site-dot-ssh host host-name user port identity-file user-known-hosts-file }/bin/single-site-dot-ssh" { } ;
	ssh-keygen = passphrase : utils.structure utils.structures-dir "${ derivations.ssh-keygen passphrase }/bin/ssh-keygen" { } ;
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
 	    pkgs.signing-party
	    pkgs.pinentry-curses
	    derivations.rebuild-nixos
	    derivations.pass-kludge-pinentry
	    pkgs.emacs
	    ( derivations.foo ( literal "b59c8073-29be-4425-966c-e215101e3448" ) )
	    ( derivations.foobar ( structure-dir ( structures.foo ( literal "b2b48732-9547-4e14-bb8f-31fed11cc8d6" ) ) ) )
	    ( derivations.post-commit ( literal "origin" ) )
	    ( structures.multiple-site-dot-ssh ( structure-files [ ( structures.single-site-dot-ssh ( literal "upstream" ) ( literal "github.com" ) ( literal "git" ) ( literal 22 ) ( structure-file ( structures.ssh-keygen ( structure-cat ( structures.personal-identification-number ( literal "pin.asc" ) ( literal 6 ) ( literal "67b4e892-ef69-4253-9e21-459a1c33645a" ) ) "pin.asc" ) ) "id-rsa.asc" ) ( structure-file ( utils.system-secret "upstream.known_hosts" "known-hosts.asc" ) "known-hosts.asc" ) ) ] "config" ) )
	    ( derivations.ssh ( structure-file ( structures.multiple-site-dot-ssh ( structure-files [ ( structures.single-site-dot-ssh ( literal "upstream" ) ( literal "github.com" ) ( literal "git" ) ( literal 22 ) ( structure-file ( structures.ssh-keygen ( structure-cat ( structures.personal-identification-number ( literal "pin.asc" ) ( literal 6 ) ( literal "67b4e892-ef69-4253-9e21-459a1c33645a" ) ) "pin.asc" ) ) "id-rsa.asc" ) ( structure-file ( utils.system-secret "upstream.known_hosts" "known-hosts.asc" ) "known-hosts.asc" ) ) ] "config" ) ) "config" ) )
	    ( derivations.pass "system-secrets" ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGithub "nextmoose" "secrets" "7c044d920affadca7e66458a7560d8d40f9272ec" "1xnja2sc704v0qz94k9grh06aj296lmbgjl7vmwpvrgzg40bn25l" ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; } ; } )
        ] ;
    } ;
}

