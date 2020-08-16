{ pkgs ? import <nixpkgs> { } } : let
    literal = value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : utils.export name ( builtins.toString value ) ;
	format = fun : fun value ;
    } ;
    literal-file = file-name : value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : utils.export name ( "${ builtins.toString value }/${ file-name }" ) ;
	format = fun : fun value ;
    } ;
    literal-cat = file-name : value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : utils.export name ( "$( ${ pkgs.coreutils }/bin/cat ${ builtins.toString value }/${ file-name } )" ) ;
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
	format = fun : fun "\\\$( ${ value }/bin/structure )/${ file-name }" ;
    } ;
    structure-cat = file-name : value : {
	unlock = "${ pkgs.coreutils }/bin/true" ;
	export = name : utils.export name "$( ${ pkgs.coreutils }/bin/cat \"$( ${ value }/bin/structure )/${ file-name }\" )" ;
	format = fun : fun "$( ${ pkgs.coreutils }/bin/cat \"$( ${ value }/bin/structure )/${ file-name }\" )" ;
    } ;
    scripts = {
    } ;
    utils = {
        export = name : value : "--run \"${ utils.replace-strings "export ${ utils.upper-case name }=\"${ builtins.toString value }\"" }\"" ;
	helloworldsha256 = "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e" ;
        name-it = named : builtins.listToAttrs ( builtins.map ( name : { name = name ; value = builtins.getAttr name named name ; } ) ( builtins.attrNames named ) ) ;
	replace-strings = string : builtins.replaceStrings [ "\"" "\$" ] [ "\\\"" "\\\$" ] string ;
        sh-derivation = name : sets : args : dependencies : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./public/scripts + ("/" + name) ;
	    buildInputs = [ pkgs.coreutils pkgs.makeWrapper ] ;
	    installPhase = ''
	        mkdir $out &&
		    cp --recursive . $out/src &&
		    if [ -f $out/src/${ name }.sh ]
		    then
		        chmod 0500 $out/src/${ name }.sh &&
			    makeWrapper $out/src/${ name }.sh $out/bin/${ name } ${ builtins.concatStringsSep " " ( builtins.map ( name : ( builtins.getAttr name sets ).export ( utils.upper-case name ) ) ( builtins.attrNames sets ) ) } --run "export STORE_DIR=$out" --run "export PATH=${ pkgs.lib.makeBinPath dependencies }" --add-flags "${ builtins.concatStringsSep " " ( builtins.map ( arg : arg.format ( x : x ) ) args ) }"
		    fi
	    '' ;
	} ;
	structure = constructor-program : options : derivations.structure constructor-program derivations.destructor options ;
	upper-case = string : builtins.replaceStrings [ "-" "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k" "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v" "w" "x" "y" "z" ] [ "_" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z" ] string ;
    } ;
    derivations = utils.name-it {
        aws-s3-dir = name : bucket : utils.sh-derivation name { bucket = bucket ; } [ ] [ pkgs.awscli ] ;
	aws-s3-dir-retire = name : structure-dir : bucket : utils.sh-derivation { structure-dir = structure-dir ; bucket = bucket ; } [ ] [ pkgs.awscli pkgs.coreutils ] ;
	destructor = name : utils.sh-derivation name { } [ ] [ pkgs.coreutils ] ;
	dot-gnupg = name : gpg-private-keys : gpg-ownertrust : gpg2-private-keys : gpg2-ownertrust : utils.sh-derivation name { gpg-private-keys = gpg-private-keys ; gpg-ownertrust = gpg-ownertrust ; gpg2-private-keys = gpg2-private-keys ; gpg2-ownertrust = gpg2-ownertrust ; } [ ] [ pkgs.coreutils pkgs.gnupg ] ;
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
	firefox = name : home : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = public/empty ;
	    buildInputs = [ pkgs.makeWrapper ] ;
	    installPhase = ''
	        makeWrapper ${ pkgs.firefox }/bin/firefox $out/bin/firefox ${ home.export "home" }
	    '' ;
	} ;
        foo = name : uuid : utils.sh-derivation name { uuid = uuid ; } [ ] [ pkgs.coreutils ] ;
	foobar = name : literal : dir : file : cat : utils.sh-derivation name { literal = literal ; dir = dir ; file = file ; cat = cat ; } [ ] [ pkgs.coreutils ] ;
	github-create-public-key = name : personal-access-token : title : ssh-public-key : utils.sh-derivation name { personal-access-token = personal-access-token ; title = title ; ssh-public-key = ssh-public-key ; } [ ] [ pkgs.curl ] ;
	github-delete-public-key = name : personal-access-token : create-dir : utils.sh-derivation name { personal-access-token = personal-access-token ; create-dir = create-dir ; } [ ] [ pkgs.coreutils pkgs.curl pkgs.jq ] ;
	git-project = name : ssh-program : post-commit-program : committer-name : committer-email : upstream-url : personal-url : report-url : personal-branch : utils.sh-derivation name { ssh-program = ssh-program ; post-commit-program = post-commit-program ; committer-name = committer-name ; committer-email = committer-email ; upstream-url = upstream-url ; personal-url = personal-url ; report-url = report-url ; personal-branch = personal-branch ; } [ ] [ pkgs.coreutils pkgs.git ] ;
	multiple-site-dot-ssh = name : configs : utils.sh-derivation name { } configs [ pkgs.coreutils ] ;
	pass = name : program-name : dot-gnupg : password-store-dir : extensions : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./public/empty ;
	    buildInputs = [ pkgs.gnused pkgs.makeWrapper ] ;
	    installPhase = ''
	        makeWrapper ${ pkgs.pass }/bin/pass $out/bin/${ program-name } ${ dot-gnupg.format ( dir : "--run \"export PASSWORD_STORE_GPG_OPTS=\\\"--homedir ${ dir }\\\"\"" ) } ${ password-store-dir.export "PASSWORD_STORE_DIR" } --run "export PASSWORD_STORE_ENABLE_EXTENSIONS=\"true\"" --run "export PASSWORD_STORE_EXTENSIONS_DIR=\"$out/extensions\""
		${ builtins.concatStringsSep "\n" ( builtins.map ( name : "makeWrapper ${ ( builtins.getAttr name extensions ).program } $out/extensions/${ name }.bash" ) ( builtins.attrNames extensions ) ) }
		sed -e "s#PASSWORD_STORE_EXTENSION_COMMANDS#PASSWORD_STORE_EXTENSION_COMMANDS_$( basename $out | tr '-' '_' | tr 'a-z' 'A-Z' )#" -e "s#_pass#_pass_$( basename $out )#g" -e "s# pass# ${ program-name }#g" -e "s#.{PASSWORD_STORE_DIR:-\$HOME/[.]password-store/}#${ password-store-dir.format ( dir : dir ) }#" -e "w$out/pass-completions.sh" ${ pkgs.pass }/share/bash-completion/completions/pass
		mkdir $out/completions
		${ builtins.concatStringsSep "\n" ( builtins.map ( name : "sed -e \"s#_pass#_pass_$( basename $out )#g\" -e \"s#COMMAND#${ name }#g\" -e \"w$out/completions/${ name }.sh\" ${ ( builtins.getAttr name extensions ).completion }" ) ( builtins.filter ( name : builtins.hasAttr "completion" ( builtins.getAttr name extensions ) ) ( builtins.attrNames extensions ) ) ) }
		( cat > $out/completions.sh <<EOF
#!/bin/sh

source $out/pass-completions.sh
PASSWORD_STORE_EXTENSION_COMMANDS_$( basename $out | tr '-' '_' | tr 'a-z' 'A-Z' )=( ${ builtins.concatStringsSep " " ( builtins.attrNames extensions ) } )
${ builtins.concatStringsSep "\n" ( builtins.map ( name : "source $out/completions/${ name }.sh" ) ( builtins.filter ( name : builtins.hasAttr "completion" ( builtins.getAttr name extensions ) ) ( builtins.attrNames extensions ) ) ) }
EOF
		)
	    '' ;
	} ;
	pass-expiry = name : utils.sh-derivation name { } [ ] [ pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.pass ] ;
	pass-file = name : pass-name : dot-gnupg : password-store-dir : utils.sh-derivation name { pass-name = pass-name ; dot-gnupg = dot-gnupg ; password-store-dir = password-store-dir ; } [ ] [ pkgs.coreutils pkgs.pass ] ;
	pass-kludge-pinentry = name : utils.sh-derivation name { } [ ] [ pkgs.coreutils pkgs.gnupg ] ;
	pass-kludge-start = name : starter-branch : new-branch : utils.sh-derivation name { starter-branch = starter-branch ; new-branch = new-branch ; } [ ] [ pkgs.pass ] ;
	personal-identification-number = name : digits : uuid : utils.sh-derivation name { digits = digits ; uuid = uuid ; } [ ] [ pkgs.coreutils ] ;
	post-commit = name : remote : utils.sh-derivation name { remote = remote ; } [ ] [ pkgs.coreutils pkgs.git ] ;
	rebuild-nixos = name : utils.sh-derivation name { } [ ] [ pkgs.coreutils pkgs.gnugrep pkgs.rsync pkgs.systemd ] ;
	shell = name : attribute-name : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./public/empty ;
	    buildInputs = [ pkgs.makeWrapper ] ;
	    installPhase = ''
	        makeWrapper ${ pkgs.nix }/bin/nix-shell $out/bin/${ attribute-name } --add-flags "${ ./. }/default.nix --attr ${ attribute-name } --show-trace"
	    '' ;
	} ;
	single-site-dot-ssh = name : host : host-name : user : port : identity-file : user-known-hosts-file : utils.sh-derivation name { host = host ; host-name = host-name ; user = user ; port = port ; identity-file = identity-file ; user-known-hosts-file = user-known-hosts-file ; } [ ] [ pkgs.coreutils pkgs.gnused ] ;
	ssh = name : configs : pkgs.stdenv.mkDerivation {
	    name = name ;
	    src = ./public/empty ;
	    buildInputs = [ pkgs.makeWrapper ] ;
	    installPhase = ''
	        makeWrapper ${ pkgs.openssh }/bin/ssh $out/bin/ssh --add-flags "-F ${ configs.format ( file : file ) }"
	    '' ;
	} ;
	ssh-keygen = name : passphrase : utils.sh-derivation name { passphrase = passphrase ; } [ ] [ pkgs.coreutils pkgs.openssh ] ;
	structure = name : constructor-program : destructor : { structures-dir ? "/home/user/.structures" , has-scheduled-destruction ? false , cleaner-program ? "${ pkgs.coreutils }/bin/true" , salt ? "" , salt-program ? "${ pkgs.coreutils }/bin/true" , seconds ? 60 * 60 } : utils.sh-derivation name { structures-dir = literal structures-dir ; constructor-program = literal constructor-program ; has-scheduled-destruction = literal has-scheduled-destruction ; cleaner-program = literal cleaner-program ; salt = literal salt ; salt-program = literal salt-program ; seconds = literal seconds ; destructor-program = literal "${ destructor }/bin/destructor" ; } [ ] [ pkgs.coreutils pkgs.utillinux ] ;
    } ;
    structures = {
        aws-s3-dir = bucket : utils.structure "${ derivations.aws-s3-dir bucket }/bin/aws-s3-dir" { } ;
        dot-gnupg = gpg-private-keys : gpg-ownertrust : gpg2-private-keys : gpg2-ownertrust : utils.structure "${ derivations.dot-gnupg gpg-private-keys gpg-ownertrust gpg2-private-keys gpg2-ownertrust }/bin/dot-gnupg" { } ;
        foo = uuid : utils.structure "${ derivations.foo uuid }/bin/foo" { } ;
	github-create-public-key = personal-access-token : title : ssh-public-key : utils.structure "${ derivations.github-create-public-key personal-access-token title ssh-public-key }/bin/github-create-public-key" { } ;
	github-delete-public-key = personal-access-token : create-dir : utils.structure "${ derivations.github-delete-public-key personal-access-token create-dir }/github-delete-public-key" { } ;
	git-project = ssh-program : post-commit-program : committer-name : committer-email : upstream-url : personal-url : remote-url : personal-branch : utils.structure "${ derivations.git-project ssh-program post-commit-program committer-name committer-email upstream-url personal-url remote-url personal-branch }/bin/git-project" { } ;
	multiple-site-dot-ssh = configs : utils.structure "${ derivations.multiple-site-dot-ssh configs }/bin/multiple-site-dot-ssh" { } ;
	pass-file = pass-name : dot-gnupg : password-store-dir : utils.structure "${ derivations.pass-file pass-name dot-gnupg password-store-dir }/bin/pass-file" { } ;
	personal-identification-number = digits : uuid : utils.structure "${ derivations.personal-identification-number digits uuid }/bin/personal-identification-number" { } ;
	single-site-dot-ssh = host : host-name : user : port : identity-file : user-known-hosts-file : utils.structure "${ derivations.single-site-dot-ssh host host-name user port identity-file user-known-hosts-file }/bin/single-site-dot-ssh" { } ;
	ssh-keygen = passphrase : utils.structure "${ derivations.ssh-keygen passphrase }/bin/ssh-keygen" { } ;
	temporary = salt : utils.structure "${ pkgs.coreutils }/bin/true" { salt = salt ; } ;
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
        aws-s3-dir = structures.aws-s3-dir ( literal "bffbdc36-383c-4b4e-b041-a420f3bf146c" ) ;
        boot-commit = "da590c0eefeb80b4691b99854df13a5e037a50db" ;
	boot-sha256 = "1ssm4bmmds58y8rim8w1x77cgn81lsdr7sfrhz8wr1c5rjjjc2xi" ;
        boot = {
	    gpg-ownertrust = structures.pass-file ( literal "gpg-ownertrust" ) ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGitHub "nextmoose" "secrets" boot-commit boot-sha256 ) ) ;
	    gpg-private-keys = structures.pass-file ( literal "gpg-private-keys" ) ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGitHub "nextmoose" "secrets" boot-commit boot-sha256 ) ) ;
	    gpg2-ownertrust = structures.pass-file ( literal "gpg2-ownertrust" ) ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGitHub "nextmoose" "secrets" boot-commit boot-sha256 ) ) ;
	    gpg2-private-keys = structures.pass-file ( literal "gpg2-private-keys" ) ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGitHub "nextmoose" "secrets" boot-commit boot-sha256 ) ) ;
	    personal-access-token = structures.pass-file ( literal "personal-access-token" ) ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGitHub "nextmoose" "secrets" boot-commit boot-sha256 ) ) ;
	    user-known-hosts-file = structures.pass-file ( literal "user-known-hosts" ) ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGitHub "nextmoose" "secrets" boot-commit boot-sha256 ) ) ;
	} ;
        boot-secrets = derivations.pass "boot-secrets" ( structure-dir ( structures.dot-gnupg ( literal ./private/gpg-private-keys.asc ) ( literal ./private/gpg-ownertrust.asc ) ( literal ./private/gpg2-private-keys.asc ) ( literal ./private/gpg2-ownertrust.asc ) ) ) ( literal ( derivations.fetchFromGitHub "nextmoose" "secrets" boot-commit boot-sha256 ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; } ;
        dot-ssh = structures.multiple-site-dot-ssh [ ( structure-file "config" upstream-dot-ssh ) ( structure-file "config" personal-dot-ssh ) ( structure-file "config" report-dot-ssh ) ] ;
	github-create-public-key = host : id-rsa : structures.github-create-public-key ( structure-cat "secret.asc" boot.personal-access-token ) ( literal host ) ( structure-cat "id-rsa.pub" id-rsa ) ;
	github-delete-public-key = create-dir : structures.github-delete-public-key ( structure-cat "secret.asc" boot.personal-access-token ) ( structure-dir create-dir ) ;
	nix-ide = ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/nix.git" ) ( literal "personal:nextmoose/nix.git" ) ( literal "report:nextmoose/nix.git" ) ( literal "scratch/34bdfa2d-908c-4824-bfa4-54f6c4d25f83" ) ) ;
	personal-dot-ssh = structures.single-site-dot-ssh ( literal "personal" ) ( literal "github.com" ) ( literal "git" ) ( literal 22 ) ( structure-file "id-rsa" personal-id-rsa ) ( structure-file "secret.asc" boot.user-known-hosts-file ) ;
        personal-id-rsa = structures.ssh-keygen ( structure-cat "pin.asc" ( structures.personal-identification-number ( literal 0 ) ( literal "a6104037-4036-4cde-8b10-a8de9f6e3145" ) ) ) ;
	report-dot-ssh = structures.single-site-dot-ssh ( literal "report" ) ( literal "github.com" ) ( literal "git" ) ( literal 22 ) ( structure-file "id-rsa" report-id-rsa ) ( structure-file "secret.asc" boot.user-known-hosts-file ) ;
        report-id-rsa = structures.ssh-keygen ( structure-cat "pin.asc" report-pin ) ;
        report-pin = structures.personal-identification-number ( literal 6 ) ( literal "bac2c05d-1668-4dd9-9d6e-8729d7673811" ) ;
	secrets = [
	    boot-secrets
	    system-secrets
	    ( derivations.pass "old-browser-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/browser-secrets.git" ) ( literal "personal:nextmoose/browser-secrets.git" ) ( literal "report:nextmoose/browser-secrets.git" ) ( literal "e0391736-347e-4d3c-9265-033952061534" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; } )
	    ( derivations.pass "finra-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "0752e40f-e308-4840-a073-2fc3ab554558" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; kludge-start = { program = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "0752e40f-e308-4840-a073-2fc3ab554558" ) }/bin/pass-kludge-start" ; completion = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "0752e40f-e308-4840-a073-2fc3ab554558" ) }/src/completion.sh" ; } ; expiry = { program = "${ derivations.pass-expiry }/bin/pass-expiry" ; completion = "${ derivations.pass-expiry }/src/completion.sh " ; } ; } )
	    ( derivations.pass "aws-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "4bac4dda-1908-4b1b-a8ee-93756613485b" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; kludge-start = { program = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "4bac4dda-1908-4b1b-a8ee-93756613485b" ) }/bin/pass-kludge-start" ; completion = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "4bac4dda-1908-4b1b-a8ee-93756613485b" ) }/src/completion.sh" ; } ; expiry = { program = "${ derivations.pass-expiry }/bin/pass-expiry" ; completion = "${ derivations.pass-expiry }/src/completion.sh " ; } ; } )
	    ( derivations.pass "xxx-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "0fd6727f-e59e-4890-9770-e3f3e3ee02fd" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; kludge-start = { program = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "0fd6727f-e59e-4890-9770-e3f3e3ee02fd" ) }/bin/pass-kludge-start" ; completion = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "0fd6727f-e59e-4890-9770-e3f3e3ee02fd" ) }/src/completion.sh" ; } ; expiry = { program = "${ derivations.pass-expiry }/bin/pass-expiry" ; completion = "${ derivations.pass-expiry }/src/completion.sh " ; } ; } )
	    ( derivations.pass "browser-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "0e91529f-1ef7-48dd-a100-775712cbaa5a" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; kludge-start = { program = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "0e91529f-1ef7-48dd-a100-775712cbaa5a" ) }/bin/pass-kludge-start" ; completion = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "0e91529f-1ef7-48dd-a100-775712cbaa5a" ) }/src/completion.sh" ; } ; expiry = { program = "${ derivations.pass-expiry }/bin/pass-expiry" ; completion = "${ derivations.pass-expiry }/src/completion.sh " ; } ; } )
	    ( derivations.pass "challenge-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "241a8a8a-e7c5-40b3-98ee-d7097aaf5d59" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; kludge-start = { program = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "241a8a8a-e7c5-40b3-98ee-d7097aaf5d59" ) }/bin/pass-kludge-start" ; completion = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "241a8a8a-e7c5-40b3-98ee-d7097aaf5d59" ) }/src/completion.sh" ; } ; } )
	    ( derivations.pass "other-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "c2be7c67-bc79-405b-800e-b3e4bba8d32e" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; kludge-start = { program = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "c2be7c67-bc79-405b-800e-b3e4bba8d32e" ) }/bin/pass-kludge-start" ; completion = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "c2be7c67-bc79-405b-800e-b3e4bba8d32e" ) }/src/completion.sh" ; } ; } )
	    ( derivations.pass "document-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "24820386-f632-4250-9c8e-5e787562d865" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; kludge-start = { program = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "24820386-f632-4250-9c8e-5e787562d865" ) }/bin/pass-kludge-start" ; completion = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "24820386-f632-4250-9c8e-5e787562d865" ) }/src/completion.sh" ; } ; } )
	    ( derivations.pass "not-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "103ab019-306a-41da-9214-02808246151c" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; kludge-start = { program = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "103ab019-306a-41da-9214-02808246151c" ) }/bin/pass-kludge-start" ; completion = "${ derivations.pass-kludge-start ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ( literal "103ab019-306a-41da-9214-02808246151c" ) }/src/completion.sh" ; } ; } )
	    ( derivations.pass "start-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "ece43b24-7eb0-4a8e-a892-5a368489c7f0" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; } )
	] ;
	ssh = derivations.ssh ( structure-file "config" dot-ssh ) ;
        system-secrets = derivations.pass "system-secrets" ( structure-dir ( structures.dot-gnupg ( structure-file "secret.asc" boot.gpg-private-keys ) ( structure-file "secret.asc" boot.gpg-ownertrust ) ( structure-file "secret.asc" boot.gpg2-private-keys ) ( structure-file "secret.asc" boot.gpg2-ownertrust ) ) ) ( structure-dir ( structures.git-project ( literal "${ ssh }/bin/ssh" ) ( literal "${ derivations.post-commit ( literal "personal" ) }/bin/post-commit" ) ( literal "Emory Merryman" ) ( literal "emory.merryman@gmail.com" ) ( literal "upstream:nextmoose/secrets.git" ) ( literal "personal:nextmoose/secrets.git" ) ( literal "report:nextmoose/secrets.git" ) ( literal "8e81930b-25e9-4efd-be0f-da8fa180b206" ) ) ) { kludge-pinentry = { program = "${ derivations.pass-kludge-pinentry }/bin/pass-kludge-pinentry" ; completion = "${ derivations.pass-kludge-pinentry }/src/completion.sh" ; } ; } ;
	upstream-dot-ssh = structures.single-site-dot-ssh ( literal "upstream" ) ( literal "github.com" ) ( literal "git" ) ( literal 22 ) ( structure-file "id-rsa" upstream-id-rsa ) ( structure-file "secret.asc" boot.user-known-hosts-file ) ;
        upstream-id-rsa = structures.ssh-keygen ( structure-cat "pin.asc" ( structures.personal-identification-number ( literal 0 ) ( literal "895aab81-65aa-4df6-a422-9851db702329" ) ) ) ;
	create-public-key = {
	    upstream = github-create-public-key "upstream" upstream-id-rsa ;
	    personal = github-create-public-key "personal" personal-id-rsa ;
	    report = github-create-public-key "report" report-id-rsa ;
	} ;
    in pkgs.mkShell {
        shellHook = ''
	    cleanup() {
	        ${ github-delete-public-key create-public-key.upstream }/bin/structure &&
	            ${ github-delete-public-key create-public-key.personal }/bin/structure &&
	            ${ github-delete-public-key create-public-key.report }/bin/structure &&
		    ${ derivations.aws-s3-dir-retire aws-s3-dir literal "bffbdc36-383c-4b4e-b041-a420f3bf146c" ) }/bin/aws-s3-dir-retire &&
		    true
	    } &&
	        trap cleanup EXIT &&
	        export REPORT_PIN=$( ${ pkgs.coreutils }/bin/cat $( ${ report-pin }/bin/structure )/pin.asc ) &&
	        ${ boot-secrets }/bin/boot-secrets kludge-pinentry user-known-hosts &&
		${ create-public-key.upstream }/bin/structure &&
		${ create-public-key.personal }/bin/structure &&
		${ create-public-key.report }/bin/structure &&
	        ${ system-secrets }/bin/system-secrets kludge-pinentry user-known-hosts &&
	        ${ builtins.concatStringsSep "&& \n" ( builtins.map ( secret : "source ${ secret }/completions.sh" ) secrets ) }
		export NIX_IDE=$( ${ nix-ide }/bin/structure ) &&
		export HOME=$( ${ aws-s3-dir }/bin/structure ) &&
		cd $HOME &&
		true
	'' ;
	buildInputs = builtins.concatLists [ secrets [
	    pkgs.awscli
	    ( derivations.firefox ( structure-dir ( structures.temporary "b1f835d0-95cd-4201-b9b8-84693f9a049e" ) ) )
	] ] ;
    } ;
}
