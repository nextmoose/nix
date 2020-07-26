{ pkgs ? import <nixpkgs> { } } : let
    literal = value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : utils.export name ( builtins.toString value ) ;
	format = fun : fun value ;
    } ;
    structure-dir = value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : utils.export name "$( ${ value }/bin/structure )" ;
	format = fun : fun "\\\$( ${ value }/bin/structure )" ;
    } ;
    structure-file = file-name : value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : utils.export name "$( ${ value }/bin/structure )/${ file-name }" ;
	format = fun : fun "$( ${ value }/bin/structure )/${ file-name }" ;
    } ;
    structure-cat = file-name : value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : utils.export name "$( ${ pkgs.coreutils }/bin/cat \"$( ${ value }/bin/structure )/${ file-name }\" )" ;
	format = fun : fun "$( ${ pkgs.coreutils }/bin/cat \"$( ${ value }/bin/structure )/${ file-name }\" )" ;
    } ;
    utils = {
        export = name : value : "--run \"${ utils.replace-strings "export ${ utils.upper-case name }=\"${ builtins.toString value }\"" }\"" ;
	helloworldsha256 = "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e" ;
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
	dot-gnupg = name : gpg-private-keys : gpg-ownertrust : gpg2-private-keys : gpg2-ownertrust : utils.sh-derivation name { gpg-private-keys = gpg-private-keys ; gpg-ownertrust = gpg-ownertrust ; gpg2-private-keys = gpg2-private-keys ; gpg2-ownertrust = gpg2-ownertrust ; } [ pkgs.coreutils pkgs.gnupg ] ;
	fetchFromGitHub = name : owner : repo : rev : sha256 : pkgs.stdenv.mkDerivation {
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
	foobar = name : literal : dir : file : cat : utils.sh-derivation name { literal = literal ; dir = dir ; file = file ; cat = cat ; } [ pkgs.coreutils ] ;
	pass = name : program-name : dot-gnupg : password-store-dir : extensions : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./public/empty ;
	    buildInputs = [ pkgs.gnused pkgs.makeWrapper ] ;
	    installPhase = ''
	        makeWrapper ${ pkgs.pass }/bin/pass $out/bin/${ program-name } ${ dot-gnupg.format ( dir : "--run \"export PASSWORD_STORE_GPG_OPTS=\\\"--homedir ${ dir }\\\"\"" ) } ${ password-store-dir.export "PASSWORD_STORE_DIR" } --run "export PASSWORD_STORE_ENABLE_EXTENSIONS=\"true\"" --run "export PASSWORD_STORE_EXTENSIONS_DIR=\"$out/extensions\""
		${ builtins.concatStringsSep "\n" ( builtins.map ( name : "makeWrapper ${ ( builtins.getAttr name extensions ).program } $out/extensions/${ name }.bash" ) ( builtins.attrNames extensions ) ) }
		sed -e "s#_pass#_pass_$( basename $out )#g" -e "s# pass# ${ program-name }#g" -e "s#.{PASSWORD_STORE_DIR:-\$HOME/[.]password-store/}#${ password-store-dir.format ( dir : dir ) }#" -e "w$out/pass-completions.sh" ${ pkgs.pass }/share/bash-completion/completions/pass
		mkdir $out/completions
		${ builtins.concatStringsSep "\n" ( builtins.map ( name : "sed -e \"s#_pass#_pass_$( basename $out )#g\" -e \"s#COMMAND#${ name }#g\" -e \"w$out/completions/${ name }.sh\" ${ ( builtins.getAttr name extensions ).completion }" ) ( builtins.filter ( name : builtins.hasAttr "completion" ( builtins.getAttr name extensions ) ) ( builtins.attrNames extensions ) ) ) }
		( cat > $out/completions.sh <<EOF
#!/bin/sh

source $out/pass-completions.sh
PASSWORD_STORE_EXTENSION_COMMANDS=( ${ builtins.concatStringsSep " " ( builtins.attrNames extensions ) } )
${ builtins.concatStringsSep "\n" ( builtins.map ( name : "source $out/completions/${ name }.sh" ) ( builtins.filter ( name : builtins.hasAttr "completion" ( builtins.getAttr name extensions ) ) ( builtins.attrNames extensions ) ) ) }
EOF
		)
	    '' ;
	} ;
	pass-kludge-pinentry = name : utils.sh-derivation name { } [ pkgs.coreutils pkgs.gnupg ] ;
	personal-identification-number = name : digits : uuid : utils.sh-derivation name { digits = digits ; uuid = uuid ; } [ pkgs.coreutils ] ;
	post-commit = name : remote : utils.sh-derivation name { remote = remote ; } [ pkgs.coreutils pkgs.git ] ;
	rebuild-nixos = name : utils.sh-derivation name { } [ pkgs.coreutils pkgs.gnugrep pkgs.rsync pkgs.systemd ] ;
	shell = name : attribute-name : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./public/empty ;
	    buildInputs = [ pkgs.makeWrapper ] ;
	    installPhase = ''
	        makeWrapper ${ pkgs.nix }/bin/nix-shell $out/bin/${ attribute-name } --add-flags "./default.nix --attr ${ attribute-name }"
	    '' ;
	} ;
	ssh-keygen = name : passphrase : utils.sh-derivation name { passphrase = passphrase ; } [ pkgs.coreutils pkgs.openssh ] ;
	structure = name : constructor-program : destructor : { structures-dir ? "/home/user/.structures" , cleaner-program ? "${ pkgs.coreutils }/bin/true" , salt-program ? "${ pkgs.coreutils }/bin/true" , seconds ? 60 * 60 } : utils.sh-derivation name { structures-dir = literal structures-dir ; constructor-program = literal constructor-program ; cleaner-program = literal cleaner-program ; salt-program = literal salt-program ; seconds = literal seconds ; destructor-program = literal "${ destructor }/bin/destructor" ; } [ pkgs.coreutils pkgs.utillinux ] ;
    } ;
    structures = {
        dot-gnupg = gpg-private-keys : gpg-ownertrust : gpg2-private-keys : gpg2-ownertrust : utils.structure "${ derivations.dot-gnupg gpg-private-keys gpg-ownertrust gpg2-private-keys gpg2-ownertrust }/bin/dot-gnupg" { } ;
        foo = uuid : utils.structure "${ derivations.foo uuid }/bin/foo" { } ;
	personal-identification-number = digits : uuid : utils.structure "${ derivations.personal-identification-number digits uuid }/bin/personal-identification-number" { } ;
	ssh-keygen = passphrase : utils.structure "${ derivations.ssh-keygen passphrase }/bin/ssh-keygen" { } ;
    } ;
in {
    configuration = config : {
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
	        pkgs.emacs
	        pkgs.git
	        pkgs.gnupg
	        pkgs.gpgme
	        pkgs.keychain
 	        pkgs.signing-party
	        pkgs.pinentry-curses
	        ( derivations.shell "shell" )
	        ( derivations.post-commit ( literal "origin" ) )
	        derivations.rebuild-nixos
	        ( derivations.foo ( literal "8ee9f204-e76f-4254-92fc-96ea94a0e88f" ) )
	        ( derivations.foobar ( literal "6c63a1d6-a6f3-42b0-8b1e-8364e0b0b4bf" ) ( structure-dir ( structures.foo ( literal "1f5df803-dfa8-459a-aabd-916bda0a20c7" ) ) ) ( structure-file "uuid.txt" ( structures.foo ( literal "1f5df803-dfa8-459a-aabd-916bda0a20c7" ) ) ) ( structure-cat "uuid.txt" ( structures.foo ( literal "1f5df803-dfa8-459a-aabd-916bda0a20c7" ) ) ) )
            ] ;
        } ;
    } ;
    shell = let
        personal-id-rsa = structures.ssh-keygen ( structures.personal-identification-number ( literal 0 ) ( literal "a6104037-4036-4cde-8b10-a8de9f6e3145" ) ) ;
        report-pin = structures.personal-identification-number ( literal 6 ) ( literal "bac2c05d-1668-4dd9-9d6e-8729d7673811" ) ;
        report-id-rsa = structures.ssh-keygen ( structures.personal-identification-number ( literal 0 ) report-pin ) ;
        system-secrets = derivations.pass "system-secrets" ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGitHub "nextmoose" "secrets" "7c044d920affadca7e66458a7560d8d40f9272ec" "1xnja2sc704v0qz94k9grh06aj296lmbgjl7vmwpvrgzg40bn25l" ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; } ;
        upstream-id-rsa = structures.ssh-keygen ( structures.personal-identification-number ( literal 0 ) ( literal "a6104037-4036-4cde-8b10-a8de9f6e3145" ) ) ;
    in pkgs.mkShell {
        shellHook = ''
	    export REPORT_PIN=$( ${ pkgs.coreutils }/bin/cat $( ${ report-pin }/bin/structure )/pin.asc ) &&
	        source ${ system-secrets }/completions.sh &&
	        ${ system-secrets }/bin/system-secrets kludge-pinentry uuid
		echo ${ personal-id-rsa }
		echo ${ upstream-id-rsa }
		echo ${ report-id-rsa }
	'' ;
	buildInputs = [
	    system-secrets
	    pkgs.firefox
	] ;
    } ;
}
