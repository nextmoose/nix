{ pkgs ? import <nixpkgs> { } , private-dir ? builtins.path { path = builtins.concatStringsSep "/" [ ( builtins.getEnv "HOME" ) ".magic" "private" ] ; } , structures-dir ? builtins.concatStringsSep "/" [ ( builtins.getEnv "HOME" ) ".magic" "structures" ] , seed ? "44bd8dc1-6063-49ea-88df-3866d2137c28" } : let

private = path : structure { descriptor = "private - ${ path }" ; constructor-script = "${ pkgs.coreutils }/bin/ln --symbolic ${ private-dir }/${ path } ${ builtins.baseNameOf path }" ; } ;

identification = prefix : length : uuid : builtins.concatStringsSep "" [ ( builtins.toString prefix ) ( builtins.substring 0 ( length - builtins.stringLength ( builtins.toString prefix ) ) ( builtins.hashString "sha512" ( builtins.concatStringsSep "\n" [ ( builtins.toString uuid ) ( builtins.toString prefix ) ( builtins.toString length ) ( builtins.toString seed ) ] ) ) ) ] ;

secret = dot-gnupg : password-store-dir : pass-name : { file-name ? "secret.asc" , file-permissions ? 0400 } : structure { descriptor = "secret - ${ pass-name } - ${ file-name }" ; constructor-script = ''
export PASSWORD_STORE_DIR=$( ${ password-store-dir }/bin/structure $2 )/structure &&
    export PASSWORD_STORE_GPG_OPTS="--homedir $( ${ dot-gnupg }/bin/structure $2 )/structure --batch --pinentry-mode loopback --passphrase-file $( ${ kludge-passphrase-entry-store }/bin/structure $2 )/structure/passphrase.asc" &&
    ${ pkgs.pass }/bin/pass show "${ pass-name }" > "${ file-name }" &&
    ${ pkgs.coreutils }/bin/chmod ${ builtins.toString ( file-permissions ) } "${ file-name }" &&
    ${ pkgs.coreutils }/bin/true
'' ; destructor-script = "${ pkgs.coreutils }/bin/shred --force --remove ${ file-name }" ; } ;

boot-secret = secret ( dot-gnupg ( private "gpg-private-keys.asc" ) ( private "gpg-ownertrust.asc" ) ( private "gpg2-private-keys.asc" ) ( private "gpg2-ownertrust.asc" ) ) ( git-load "https://github.com/nextmoose/secrets.git" "320d6d6e-1c95-11eb-832f-e379b175e669" "bac1efc715d10bb49a957ff148a4d85ff7aa2833" ) ;

system = {
    ssh-config = ssh-config { upstream = { host-name = "github.com" ; user = "git" ; identity-file = github-ssh-key ( boot-secret "personal-access-token" { file-name = "personal-access-token.asc" ; } ) ( personal-identification-number 0 "4310857e-b1b7-451a-ba51-4efe05fe18e8" ) ; user-known-hosts-file = boot-secret "known-hosts" { file-name = "known-hosts.asc" ; } ; } ; personal = { host-name = "github.com" ; user = "git" ; identity-file = github-ssh-key ( boot-secret "personal-access-token" { file-name = "personal-access-token.asc" ; } ) ( personal-identification-number 0 "c3ae955c-1101-41a3-839c-5d00b61d14f9" ) ;  user-known-hosts-file = boot-secret "known-hosts" { file-name = "known-hosts.asc" ; } ; } ; report = { host-name = "github.com" ; user = "git" ; identity-file = github-ssh-key ( boot-secret "personal-access-token" { file-name = "personal-access-token.asc" ; } ) ( personal-identification-number 6 "cfa74587-b45e-42c7-8124-e09ca081ef5b" ) ;  user-known-hosts-file = boot-secret "known-hosts" { file-name = "known-hosts.asc" ; } ; } ; } ;
} ;

dot-gnupg = gpg-private-keys : gpg-ownertrust : gpg2-private-keys : gpg2-ownertrust : structure { descriptor = "dot-gnupg" ; constructor-script = ''
${ pkgs.coreutils }/bin/chmod 0700 $( ${ pkgs.coreutils }/bin/pwd ) &&
    ${ pkgs.gnupg }/bin/gpg --homedir . --quiet --batch --import $( ${ gpg-private-keys }/bin/structure $2 )/structure/gpg-private-keys.asc &&
    ${ pkgs.gnupg }/bin/gpg --homedir . --quiet --import-ownertrust $( ${ gpg-ownertrust }/bin/structure $2 )/structure/gpg-ownertrust.asc &&
#    ${ pkgs.gnupg }/bin/gpg --homedir . --check-trustdb &&
    ${ pkgs.gnupg }/bin/gpg2 --homedir . --quiet --import $( ${ gpg2-private-keys }/bin/structure $2 )/structure/gpg2-private-keys.asc &&
    ${ pkgs.gnupg }/bin/gpg2 --homedir . --quiet --import-ownertrust $( ${ gpg2-ownertrust }/bin/structure $2 )/structure/gpg2-ownertrust.asc &&
#    ${ pkgs.gnupg }/bin/gpg2 --homedir . --check-trustdb &&
    ${ pkgs.coreutils }/bin/true
'' ; } ;

personal-identification-number = digits : uuid : structure { descriptor = "personal-identification-number" ; constructor-script = ''
if [ ${ builtins.toString digits } == 0 ]
then
    ${ pkgs.coreutils }/bin/touch personal-identification-number.asc &&
        ${ pkgs.coreutils }/bin/true
else
    ${ pkgs.coreutils }/bin/cat /dev/urandom | ${ pkgs.coreutils }/bin/tr --delete --complement "0-9" | ${ pkgs.coreutils }/bin/fold --width ${ builtins.toString digits } | ${ pkgs.coreutils }/bin/head --lines 1 > personal-identification-number.asc &&
        ${ pkgs.coreutils }/bin/true
fi &&
    ${ pkgs.coreutils }/bin/chmod 0400 personal-identification-number.asc &&
    ${ pkgs.coreutils }/bin/true
'' ; destructor-script = "${ pkgs.coreutils }/bin/shred --force --remove personal-identification-number.asc" ; } ;

github-ssh-key = personal-access-token : passphrase : structure { descriptor = "github-ssh-key" ; constructor-script = ''
${ pkgs.openssh }/bin/ssh-keygen -f id-rsa -P "$( ${ pkgs.coreutils }/bin/cat $( ${ passphrase }/bin/structure $2 )/passphrase.asc )" -C "generated key" &&
    ${ pkgs.coreutils }/bin/ln --symbolic $( ${ personal-access-token }/bin/structure $1 )/personal-access-token.asc . &&
    ${ pkgs.curl }/bin/curl --output response.json --request POST --header "Authorization: token $( ${ pkgs.coreutils }/bin/cat personal-access-token.asc)" --data "{\"title\": \"generated key\", \"key\":\"$( ${ pkgs.coreutils }/bin/cat id-rsa.pub )\"}" https://api.github.com/user/keys --silent &&
    ${ pkgs.coreutils }/bin/true
'' ; destructor-script = ''
${ pkgs.curl }/bin/curl --header --request DELETE --header "Authorization: token $( ${ pkgs.coreutils }/bin/cat personal-access-token.asc )" https://api.github.com/users/key/$( ${ pkgs.jq }/bin/jq -r ".key_id" response.json ) &&
    ${ pkgs.coreutils }/bin/shred --force --remove id-rsa &&
    ${ pkgs.coreutils }/bin/true
'' ; } ;

ssh-config = config : structure { descriptor = "ssh-config" ; constructor-script = ''
( ${ pkgs.coreutils }/bin/cat > config <<EOF
${ builtins.concatStringsSep "\n\n" ( builtins.map ( host-name : builtins.concatStringsSep "\n" ( builtins.concatLists [ [ "host ${ host-name }" ] ( builtins.map ( attr-name : "${ builtins.replaceStrings [ "-" ] [ "" ] attr-name } ${ if builtins.typeOf ( builtins.getAttr attr-name ( builtins.getAttr host-name config ) ) == "string" then builtins.getAttr attr-name ( builtins.getAttr host-name config ) else "$( ${ builtins.getAttr attr-name ( builtins.getAttr host-name config ) }/bin/structure \$1 )/structure/${ builtins.getAttr attr-name { identity-file = "id-rsa" ; user-known-hosts-file = "known-hosts" ; } }" }" ) ( builtins.attrNames ( builtins.getAttr host-name config ) ) ) ] ) ) ( builtins.attrNames config ) ) }
EOF
) &&
    ${ pkgs.coreutils }/bin/chmod 0400 config &&
    ${ pkgs.coreutils }/bin/true
'' ; } ;

git-load = url : ref : rev : structure { descriptor = "static git - ${ url }" ; constructor-script = "${ pkgs.coreutils }/bin/ln --symbolic ${ builtins.fetchGit { url = url ; ref = ref ; rev = rev ; } }/* ." ; } ;

git-fetch = committer-name : committer-email : ssh-config : upstream-url : upstream-branch : personal-url : personal-branch : report-url : structure { descriptor = "git-fetch ${ upstream-url }" ; constructor-script = ''
${ pkgs.git }/bin/git init &&
    ${ pkgs.coreutils }/bin/ln --symbolic ${ pkgs.writeShellScriptBin "post-commit" "while ! ${ pkgs.git }/bin/git push personal HEAD ; do ${ pkgs.coreutils }/bin/sleep 1s ; done" }/bin/post-commit .git/hooks &&
    ${ pkgs.git }/bin/git config user.name "${ committer-name }" &&
    ${ pkgs.git }/bin/git config user.email "${ committer-email }" &&
    ${ pkgs.coreutils }/bin/echo ${ pkgs.git }/bin/git config core.sshCommand "${ pkgs.openssh }/bin/ssh -F $( ${ ssh-config }/bin/structure $1 )/structure/config \$@" &&
    ${ pkgs.git }/bin/git config core.sshCommand "${ pkgs.openssh }/bin/ssh -F $( ${ ssh-config }/bin/structure $1 )/structure/config \$@" &&
    ${ pkgs.git }/bin/git remote add upstream ${ upstream-url } &&
    ${ pkgs.git }/bin/git remote set-url --push upstream no_push
    ${ pkgs.git }/bin/git remote add personal ${ personal-url } &&
    ${ pkgs.git }/bin/git remote add report ${ report-url } &&
    if ${ pkgs.git }/bin/git fetch --quiet personal ${ personal-branch }
    then
        ${ pkgs.git }/bin/git checkout --quiet ${ personal-branch } &&
	    ${ pkgs.coreutils }/bin/true
    else
        ${ pkgs.git }/bin/git fetch --quiet upstream ${ upstream-branch } &&
            ${ pkgs.git }/bin/git checkout --quiet upstream/${ upstream-branch } &&
            ${ pkgs.git }/bin/git checkout --quiet -b ${ personal-branch } &&
	    ${ pkgs.coreutils }/bin/true
    fi &&
    ${ pkgs.coreutils }/bin/true
'' ; } ;

structured-script = name : script : pkgs.writeShellScriptBin name ''
STRUCTURE_DIR=$( ${ structure { descriptor = "structured script - ${ name }" ; saltor-script = "${ pkgs.libuuid }/bin/uuidgen" ; } }/bin/structure ) &&
    # trap "${ destroy-structures }/bin/destroy-structure $STRUCTURE_DIR" EXIT &&
    ${ script }
'' ;

scripts = {
    pass = name : dot-gnupg : password-store-dir : structured-script name ''
export PASSWORD_STORE_DIR=$( ${ password-store-dir }/bin/structure $STRUCTURE_DIR )/structure
    export PASSWORD_STORE_GPG_OPTS="--homedir $( ${ dot-gnupg }/bin/structure $STRUCTURE_DIR )/structure --batch --pinentry-mode loopback --passphrase-file $( ${ kludge-passphrase-entry-store }/bin/structure )/structure/passphrase.asc" &&
    if [ -t 0 ]
    then
        ${ pkgs.coreutils }/bin/tee | ${ pkgs.pass }/bin/pass $@ &&
	    ${ pkgs.coreutils }/bin/true
    else
        ${ pkgs.pass }/bin/pass $@ &&
	    ${ pkgs.coreutils }/bin/true
    fi &&
        ${ pkgs.coreutils }/bin/true
    '' ;

   pass-completion = name : password-store-dir : pkgs.writeShellScriptBin "completion" ( builtins.replaceStrings [ "_pass" " pass" ( builtins.readFile ./prefix.asc ) ] [ "_pass_${ builtins.hashString "sha512" name }" " ${ name }" password-store-dir ] ( builtins.readFile "${ pkgs.pass }/share/bash-completion/completions/pass" ) ) ;
} ;

aws-home = access-key : secret-access-key : structure { constructor-script = ''
export HOME=$( ${ pkgs.coreutils }/bin/pwd ) &&
    ( ${ pkgs.coreutils }/bin/cat <<EOF
${ access-key }
${ secret-access-key }
us-east-1
json

EOF
    ) | ${ pkgs.awscli }/bin/aws configure
'' ; } ;

s3fs-home = bucket : access-key : secret-access-key : structure { constructor-script = ''
echo ${ bucket }:${ access-key }:${ secret-access-key } > .passwd-s3fs &&
    ${ pkgs.coreutils }/bin/chmod 0400 .passwd-s3fs &&
    ${ pkgs.coreutils }/bin/true
'' ; } ;

aws-cli = name : aws-access-key-id : aws-secret-access-key : pkgs.writeShellScriptBin name ''
export AWS_ACCESS_KEY_ID=${ aws-access-key-id } &&
    export AWS_SECRET_ACCESS_KEY=${ aws-secret-access-key } &&
    export AWS_DEFAULT_REGION=us-east-1 &&
    exec ${ pkgs.awscli }/bin/aws $@ &&
    ${ pkgs.coreutils }/bin/true
'' ;

kludge-passphrase-entry-program = dot-gnupg : encrypted-file : decrypted-file : pkgs.writeShellScriptBin "kludge-passphrase-entry-program" ''
STRUCTURE_DIR=$( ${ structure { descriptor = "kludge-passphrase-entry-program" ; saltor-script = "${ pkgs.libuuid }/bin/uuidgen" ; } }/bin/structure ) &&
    PASSPHRASE_FILE=$( ${ kludge-passphrase-entry-store }/bin/structure $STRUCTURE_DIR )/structure/passphrase.asc &&
    export GNUPGHOME=$( ${ dot-gnupg }/bin/structure $STRUCTURE_DIR )/structure &&
    while ! ${ pkgs.gnupg }/bin/gpg --batch --pinentry-mode loopback --passphrase-file $PASSPHRASE_FILE --homedir $GNUPGHOME --decrypt ${ encrypted-file } || [ "$( ${ pkgs.gnupg }/bin/gpg --batch --pinentry-mode loopback --passphrase-file $PASSPHRASE_FILE --homedir $GNUPGHOME --decrypt ${ encrypted-file } )" != "$( ${ pkgs.coreutils }/bin/cat ${ decrypted-file } )" ]
    do
	read -p "PASSPHRASE?  " -s PASSPHRASE &&
	    ${ pkgs.coreutils }/bin/echo $PASSPHRASE > $PASSPHRASE_FILE &&
	    ${ pkgs.coreutils }/bin/true
    done &&
    ${ pkgs.coreutils }/bin/chmod 0400 $PASSPHRASE_FILE &&
    ${ destroy-structures }/bin/destroy-structures $STRUCTURE_DIR &&
    ${ pkgs.coreutils }/bin/true
'' ;

kludge-passphrase-entry-store = structure { descriptor = "kludge passphrase entry store" ; destructor-script = "${ pkgs.coreutils }/bin/shred --force --remove passphrase.asc" ; } ;

structure = { root ? false , descriptor ? "" , constructor-script ? "${ pkgs.coreutils }/bin/true" , destructor-script ? "${ pkgs.coreutils }/bin/true" , saltor-script ? "${ pkgs.coreutils }/bin/true" } : let
    constructor = pkgs.writeShellScriptBin "constructor" ''
trap "${ release-locks }/bin/release-locks $STRUCTURE_DIR/" EXIT &&
${ constructor-script }
'' ;
    destructor = pkgs.writeShellScriptBin "destructor" destructor-script ;
    saltor = "${ pkgs.writeShellScriptBin "saltor" saltor-script }" ;
in pkgs.writeShellScriptBin "structure" ''
TIME_STAMP=$( ${ pkgs.coreutils }/bin/date +%s ) &&
    SALT=$( ${saltor}/bin/saltor $TIME_STAMP ) &&
    HASH=$( ${ pkgs.coreutils }/bin/echo ${ builtins.toString root } ${ descriptor } ${ constructor } ${ destructor } ${ saltor } $SALT | ${ pkgs.coreutils }/bin/sha512sum | ${ pkgs.coreutils }/bin/cut --bytes 1-128 ) &&
    LINK_DIR=${ structures-dir }/$HASH &&
    LOCK_FILE=$LINK_DIR.lock &&
    if [ ! -d ${ structures-dir } ]
    then
        ${ pkgs.coreutils }/bin/mkdir ${ structures-dir } &&
        ${ pkgs.coreutils }/bin/true
    fi &&
    (
        ( ${ pkgs.flock }/bin/flock 9 || exit 41 ) &&
            if [ -d $LINK_DIR ]
	    then
	        STRUCTURE_DIR=$( ${ pkgs.coreutils }/bin/readlink --canonicalize $LINK_DIR ) &&
	            if [ -f $STRUCTURE_DIR/fail.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Previous Failure >> $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ ! -f $STRUCTURE_DIR/root.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing root file > $STRUCTURE_DIR/root.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ "$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/root.asc )" != "${ builtins.toString ( if root then 1 else 0 ) }" ]
		    then
		        ${ pkgs.coreutils }/bin/echo Mismatched root $( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/root.asc ) != ${ builtins.toString ( if root then 1 else 0 ) } > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/root.asc ) != 400 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on root file > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ ! -f $STRUCTURE_DIR/descriptor.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing descriptor file > $STRUCTURE_DIR/descriptor.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ "$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/descriptor.asc )" != "${ descriptor }" ]
		    then
		        ${ pkgs.coreutils }/bin/echo Mismatched descriptor $( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/descriptor.asc ) != $HASH > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/descriptor.asc ) != 400 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on descriptor file > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ ! -f $STRUCTURE_DIR/hash.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing hash file > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ "$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/hash.asc )" != "$HASH" ]
		    then
		        ${ pkgs.coreutils }/bin/echo Mismatched hash $( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/hash.asc ) != $HASH > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/hash.asc ) != 400 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on hash file > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/readlink --canonicalize $STRUCTURE_DIR/constructor ) != ${ constructor } ]
		    then
		        ${ pkgs.coreutils }/bin/echo Mismatched constructor:  $( ${ pkgs.coreutils }/bin/readlink --canonicalize $STRUCTURE_DIR/constructor ) != ${ constructor } > fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/readlink --canonicalize $STRUCTURE_DIR/destructor ) != ${ destructor } ]
		    then
		        ${ pkgs.coreutils }/bin/echo Mismatched destructor:  $( ${ pkgs.coreutils }/bin/readlink --canonicalize $STRUCTURE_DIR/destructor ) != ${ destructor } > fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/readlink --canonicalize $STRUCTURE_DIR/saltor ) != ${ saltor } ]
		    then
		        ${ pkgs.coreutils }/bin/echo Mismatched saltor:  $( ${ pkgs.coreutils }/bin/readlink --canonicalize $STRUCTURE_DIR/saltor ) != ${ saltor } > fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ ! -f $STRUCTURE_DIR/salt.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing salt file > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/salt.asc ) != 400 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on salt file > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ "$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/salt.asc )" != "$SALT" ]
		    then
		        ${ pkgs.coreutils }/bin/echo Mismatched salt X $( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/salt.asc ) X != X $SALT X > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ ! -d $STRUCTURE_DIR/locks ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing locks dir $STRUCTURE_DIR/locks > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/locks ) != 700 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on locks dir > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ -d $STRUCTURE_DIR/locks.temp ]
		    then
		        ${ pkgs.coreutils }/bin/echo Temporary constructor locks dir $STRUCTURE_DIR/locks.temp was not deleted > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ ! -d $STRUCTURE_DIR/dependents ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing dependents dir $STRUCTURE_DIR/dependents > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ ! -d $STRUCTURE_DIR/dependees ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing dependees dir $STRUCTURE_DIR/dependees > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ ! -d $STRUCTURE_DIR/structure ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing structure dir $STRUCTURE_DIR/structure > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ ! -f $STRUCTURE_DIR/out.constructor.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing standard out constructor > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/out.constructor.asc ) != 400 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on standard out constructor file > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ ! -f $STRUCTURE_DIR/err.constructor.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing standard err constructor > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/err.constructor.asc ) != 400 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on standard err constructor file > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ ! -z "$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/err.constructor.asc )" ]
		    then
		        ${ pkgs.coreutils }/bin/echo Nonempty standard error constructor > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ ! -f $STRUCTURE_DIR/exit-code.constructor.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing exit-code constructor > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/exit-code.constructor.asc ) != "0" ]
		    then
		        ${ pkgs.coreutils }/bin/echo Non-zero exit-code constructor > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/exit-code.constructor.asc ) != 400 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on exit-code constructor file > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ ! -f $STRUCTURE_DIR/status.constructor.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing status constructor > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/status.constructor.asc ) != "0" ]
		    then
		        ${ pkgs.coreutils }/bin/echo Non-one status constructor > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/status.constructor.asc ) != 400 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on status file constructor > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
	            elif [ ! -f $STRUCTURE_DIR/log.asc ]
		    then
		        ${ pkgs.coreutils }/bin/echo Missing log > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
			    ${ pkgs.coreutils }/bin/true
	            elif [ $( ${ pkgs.coreutils }/bin/stat --printf %a $STRUCTURE_DIR/after.constructor.asc ) != 400 ]
		    then
		        ${ pkgs.coreutils }/bin/echo Improper permissions on after file constructor > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 41 &&
		            ${ pkgs.coreutils }/bin/true
		    elif [ $( ${ pkgs.findutils }/bin/find $STRUCTURE_DIR -mindepth 1 -maxdepth 1 | wc --lines ) != 16 ]
		    then
		        ${ pkgs.coreutils }/bin/echo There are extra files in $STRUCTURE_DIR > $STRUCTURE_DIR/fail.asc &&
		            ${ pkgs.findutils }/bin/find $STRUCTURE_DIR -mindepth 1 -maxdepth 1 >> $STRUCTURE_DIR/fail.asc &&
			    ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
			    exit 41 &&
			    ${ pkgs.coreutils }/bin/true
		    else
	                ${ pkgs.coreutils }/bin/echo $TIME_STAMP >> $STRUCTURE_DIR/log.asc &&
			    if [ $# == 1 ] && [ ! -d $1/$( ${ pkgs.coreutils }/bin/basename $STRUCTURE_DIR ) ]
			    then
			        ${ pkgs.coreutils }/bin/ln --symbolic $STRUCTURE_DIR $1 &&
				    ${ pkgs.coreutils }/bin/true
			    fi &&
		            ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
		            exit 0 &&
			    ${ pkgs.coreutils }/bin/true
		    fi &&
	            ${ pkgs.coreutils }/bin/true
	    else
	        STRUCTURE_DIR=$( ${ pkgs.mktemp }/bin/mktemp -d ${ structures-dir }/XXXXXXXX ) &&
		    ${ pkgs.coreutils }/bin/echo ${ builtins.toString ( if root then 1 else 0 ) } > $STRUCTURE_DIR/root.asc &&
		    ${ pkgs.coreutils }/bin/cat ${ builtins.toFile "descriptor.asc" descriptor } > $STRUCTURE_DIR/descriptor.asc &&
		    ${ pkgs.coreutils }/bin/echo $HASH > $STRUCTURE_DIR/hash.asc &&
	            ${ pkgs.coreutils }/bin/ln --symbolic ${ constructor } $STRUCTURE_DIR/constructor &&
	            ${ pkgs.coreutils }/bin/ln --symbolic ${ destructor } $STRUCTURE_DIR/destructor &&
	            ${ pkgs.coreutils }/bin/ln --symbolic ${ saltor } $STRUCTURE_DIR/saltor &&
		    ${ pkgs.coreutils }/bin/echo $SALT > $STRUCTURE_DIR/salt.asc &&
		    ${ pkgs.coreutils }/bin/echo $TIME_STAMP > $STRUCTURE_DIR/log.asc &&
		    ${ pkgs.coreutils }/bin/chmod 0600 $STRUCTURE_DIR/log.asc &&
		    # dependents = these structures are dependent on this structure
		    # dependeees = this structure is dependent on those structures
		    ${ pkgs.coreutils }/bin/mkdir $STRUCTURE_DIR/locks $STRUCTURE_DIR/locks.temp $STRUCTURE_DIR/dependents $STRUCTURE_DIR/dependees $STRUCTURE_DIR/structure &&
		    ${ pkgs.coreutils }/bin/chmod 0700 $STRUCTURE_DIR/locks $STRUCTURE_DIR/locks.temp &&
		    cd $STRUCTURE_DIR/structure &&
#		    if ${ constructor }/bin/constructor $STRUCTURE_DIR/locks $STRUCTURE_DIR/locks.temp > >( ${ pkgs.moreutils }/bin/ts "%Y-%m-%d %H:%M:%.S" > $STRUCTURE_DIR/out.constructor.asc ) 2> >( ${ pkgs.moreutils }/bin/ts "%Y-%m-%d %H:%M:%.S" > $STRUCTURE_DIR/err.constructor.asc ) && [ -z "$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/err.constructor.asc )" ]
		    if ${ constructor }/bin/constructor $STRUCTURE_DIR/locks $STRUCTURE_DIR/locks.temp > $STRUCTURE_DIR/out.constructor.asc 2> $STRUCTURE_DIR/err.constructor.asc && [ -z "$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/err.constructor.asc )" ]
		    then
		        ${ pkgs.coreutils }/bin/echo $? > $STRUCTURE_DIR/exit-code.constructor.asc &&
		            ${ pkgs.coreutils }/bin/echo 0 > $STRUCTURE_DIR/status.constructor.asc &&
			    ${ pkgs.coreutils }/bin/chmod 0400 $STRUCTURE_DIR/root.asc $STRUCTURE_DIR/descriptor.asc $STRUCTURE_DIR/hash.asc $STRUCTURE_DIR/salt.asc $STRUCTURE_DIR/out.constructor.asc $STRUCTURE_DIR/err.constructor.asc $STRUCTURE_DIR/exit-code.constructor.asc $STRUCTURE_DIR/status.constructor.asc &&
			    if [ $# == 1 ] && [ ! -d $1/$( ${ pkgs.coreutils }/bin/basename $STRUCTURE_DIR ) ]
			    then
			        ${ pkgs.coreutils }/bin/ln --symbolic $STRUCTURE_DIR $1 &&
				    ${ pkgs.coreutils }/bin/true
			    fi &&
			    ${ pkgs.coreutils }/bin/ln --symbolic $STRUCTURE_DIR $LINK_DIR &&
			    ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
			    exit 0 &&
	                    ${ pkgs.coreutils }/bin/true
		    else
		        ${ pkgs.coreutils }/bin/echo $? > $STRUCTURE_DIR/exit-code.constructor.asc &&
		            ${ pkgs.coreutils }/bin/echo 1 > $STRUCTURE_DIR/status.constructor.asc &&
			    ${ pkgs.coreutils }/bin/chmod 0400 $STRUCTURE_DIR/root.asc $STRUCTURE_DIR/descriptor.asc $STRUCTURE_DIR/hash.asc $STRUCTURE_DIR/salt.asc $STRUCTURE_DIR/out.constructor.asc $STRUCTURE_DIR/err.constructor.asc $STRUCTURE_DIR/exit-code.constructor.asc $STRUCTURE_DIR/status.constructor.asc &&
			    if ${ destructor }/bin/destructor > >( ${ pkgs.moreutils }/bin/ts "%Y-%m-%d %H:%M:%.S" > $STRUCTURE_DIR/out.destructor.asc ) 2> >( ${ pkgs.moreutils }/bin/ts "%Y-%m-%d %H:%M:%.S" > $STRUCTURE_DIR/err.destructor.asc ) && [ -z "$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/err.destructor.asc )" ]
			    then
			        ${ pkgs.coreutils }/bin/echo $? > $STRUCTURE_DIR/exit-code.destructor.asc &&
				    ${ pkgs.coreutils }/bin/echo 2 > $STRUCTURE_DIR/status.destructor.asc &&
				    ${ pkgs.coreutils }/bin/true
			    else
			        ${ pkgs.coreutils }/bin/echo $? > $STRUCTURE_DIR/exit-code.destructor.asc &&
				    ${ pkgs.coreutils }/bin/echo 3 > $STRUCTURE_DIR/status.destructor.asc &&
				    ${ pkgs.coreutils }/bin/true
			    fi &&
			    ${ pkgs.coreutils }/bin/chmod 0400 $STRUCTURE_DIR/log.asc $STRUCTURE_DIR/out.destructor.asc $STRUCTURE_DIR/err.destructor.asc $STRUCTURE_DIR/exit-code.destructor.asc $STRUCTURE_DIR/status.destructor.asc &&
			    ${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
                            ${ pkgs.coreutils }/bin/rm $LOCK_FILE &&
			    exit 41 &&
	                    ${ pkgs.coreutils }/bin/true
		    fi &&
	            ${ pkgs.coreutils }/bin/true
	    fi &&
            ${ pkgs.coreutils }/bin/true
    ) 9> $LOCK_FILE &&
    ${ pkgs.coreutils }/bin/true
'' ;

release-locks = pkgs.writeShellScriptBin "release-locks" ''
${ pkgs.findutils }/bin/find $1 | while read LOCK
do
    DEPENDENDEE_STRUCTURE=$( ${ pkgs.coreutils }/bin/readlink --canonicalize $LOCK ) &&
        ${ pkgs.coreutils }/bin/rm $LOCK &&
	echo DOLLAR{ destroy-structures }/bin/destroy-structures $DEPENDEE_STRUCTURE &&
        ${ pkgs.coreutils }/bin/true
done &&
    ${ pkgs.coreutils }/bin/true
'' ;

destroy-structures = pkgs.writeShellScriptBin "destroy-structures" ''
STRUCTURE_DIR=$1 &&
    if [ ! -d ${ structures-dir } ]
    then
        ${ pkgs.coreutils }/bin/mkdir ${ structures-dir } &&
            ${ pkgs.coreutils }/bin/true
    fi &&
    LINK_DIR=${ structures-dir }/$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/hash.asc ) &&
    LOCK_FILE=$LINK_DIR.lock &&
    (
        ( ${ pkgs.flock }/bin/flock 9 || exit 41 ) &&
	    if [ -z "$( ${ pkgs.findutils }/bin/find $STRUCTURES_DIR -wholename "*/[locks|locks.temp]/*" | while read LOCK ; do ${ pkgs.coreutils }/bin/readlink --canonicalize $LOCK ; done | ${ pkgs.gnugrep }/bin/grep $STRUCTURE_DIR )" ]
	    then
	        ${ pkgs.coreutils }/bin/rm $LINK_DIR $LOCK_FILE &&
	            ${ pkgs.coreutils }/bin/true
	    fi &&
	    ${ pkgs.coreutils }/bin/true
    ) 9> $LOCK_FILE &&
    if [ -z "$( ${ pkgs.findutils }/bin/find $STRUCTURES_DIR -wholename "*/locks|locks.temp/*" | while read LOCK ; do ${ pkgs.coreutils }/bin/readlink --canonicalize $LOCK ; done | ${ pkgs.gnugrep }/bin/grep $STRUCTURE_DIR )" ]
    then
        cd $STRUCTURE_DIR/structure &&
	    if $STRUCTURE_DIR/destructor/bin/destructor > >( ${ pkgs.moreutils }/bin/ts "%Y-%m-%d %H:%M:%.S" > $STRUCTURE_DIR/out.destructor.asc ) 2> >( ${ pkgs.moreutils }/bin/ts "%Y-%m-%d %H:%M:%.S" > $STRUCTURE_DIR/err.destructor.asc )
	    then
	        ${ pkgs.coreutils }/bin/echo $? > $STRUCTURE_DIR/exit-code.destructor.asc &&
		    ${ pkgs.coreutils }/bin/echo 0 > $STRUCTURE_DIR/status.destructor.asc &&
		    ${ release-locks }/bin/release-locks $STRUCTURE_DIR/locks &&
		    ${ pkgs.coreutils }/bin/true
            else
	        ${ pkgs.coreutils }/bin/echo $? > $STRUCTURE_DIR/exit-code.destructor.asc &&
		    ${ pkgs.coreutils }/bin/echo 1 > $STRUCTURE_DIR/status.destructor.asc &&
		    ${ pkgs.coreutils }/bin/true
	    fi &&
	    ${ pkgs.coreutils }/bin/chmod 0400 $STRUCTURE_DIR/log.asc $STRUCTURE_DIR/out.destructor.asc $STRUCTURE_DIR/err.destructor.asc $STRUCTURE_DIR/exit-code.destructor.asc $STRUCTURE_DIR/status.destructor.asc &&
	    ${ pkgs.coreutils }/bin/true
    fi &&
    ${ pkgs.coreutils }/bin/true
'' ;

collect-garbage = pkgs.writeShellScriptBin "collect-garbage" ''
${ pkgs.gnugrep }/bin/grep -l "^0\$" $( ${ pkgs.findutils }/bin/find ${ structures-dir } -mindepth 2 -maxdepth 2 -name status.destructor.asc ) | while read FILE
do
    ${ pkgs.coreutils }/bin/rm --recursive --force $( ${ pkgs.coreutils }/bin/dirname $FILE ) &&
        ${ pkgs.coreutils }/bin/true
done &&
    ${ pkgs.coreutils }/bin/true
'' ;

investigate-failure = pkgs.writeShellScriptBin "investigate-failure" ''
grep -l 0 ${ structures-dir }/*/status.constructor.asc | while read FILE
do
    STRUCTURE_DIR=$( ${ pkgs.coreutils }/bin/dirname $FILE ) &&
        ${ pkgs.coreutils }/bin/echo &&
        ${ pkgs.coreutils }/bin/echo &&
        ${ pkgs.coreutils }/bin/echo &&
        ${ pkgs.coreutils }/bin/echo &&
        ${ pkgs.coreutils }/bin/echo &&
        ${ pkgs.coreutils }/bin/echo &&
	${ pkgs.coreutils }/bin/echo $STRUCTURE_DIR &&
        ${ pkgs.coreutils }/bin/echo $FILE &&
        ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/err.constructor.asc &&
        ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/constructor/bin/constructor &&
        ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/out.constructor.asc &&
        ${ pkgs.coreutils }/bin/true
done &&
    ${ pkgs.coreutils }/bin/true
'' ;

investigate-links = pkgs.writeShellScriptBin "investigate-links" ''
${ pkgs.findutils }/bin/find ${ structures-dir } -mindepth 1 -maxdepth 1 -name "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????" | while read LINK_DIR
do
    LINK=$( ${ pkgs.coreutils }/bin/basename $LINK_DIR ) &&
        STRUCTURE=$( ${ pkgs.coreutils }/bin/basename $( ${ pkgs.coreutils }/bin/readlink --canonicalize $LINK_DIR ) ) &&
	DESCRIPTOR=$( ${ pkgs.coreutils }/bin/cat $( ${ pkgs.coreutils }/bin/readlink --canonicalize $LINK_DIR )/descriptor.asc ) &&
	${ pkgs.coreutils }/bin/echo -en "$LINK\t$STRUCTURE\t$DESCRIPTOR\n" &&
	${ pkgs.coreutils }/bin/true
done &&
    ${ pkgs.coreutils }/bin/true
'' ;

investigate-structures = pkgs.writeShellScriptBin "investigate-structures" ''
(
    ${ pkgs.coreutils }/bin/echo "Hash_Structure_Has Link_Constructor Status_Destructor Status_Root_Descriptor_Locks" &&
        ${ pkgs.findutils }/bin/find ${ structures-dir } -mindepth 1 -maxdepth 1 -name "????????" | while read STRUCTURE_DIR
        do
            if [ -d ${ structures-dir }/$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/hash.asc ) ]
            then
                HAS_LINK=1 &&
	            ${ pkgs.coreutils }/bin/true
            else
                HAS_LINK=0 &&
	            ${ pkgs.coreutils }/bin/true
            fi &&
                if [ -f $STRUCTURE_DIR/status.destructor.asc ]
	        then
	            IS_DESTROYED=$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/status.destructor.asc ) &&
	                ${ pkgs.coreutils }/bin/true
	        else
	            IS_DESTROYED=X &&
	                ${ pkgs.coreutils }/bin/true
	        fi &&
	        ${ pkgs.coreutils }/bin/echo -en "$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/hash.asc | ${ pkgs.coreutils }/bin/cut --bytes 1-16 )_$( ${ pkgs.coreutils }/bin/basename $STRUCTURE_DIR | ${ pkgs.coreutils }/bin/cut --bytes 1-4 )_$HAS_LINK_$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/status.constructor.asc )_$IS_DESTROYED_$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/root.asc )_$( ${ pkgs.coreutils }/bin/cat $STRUCTURE_DIR/descriptor.asc )" &&
	        find $STRUCTURE_DIR/latches -mindepth 1 -maxdepth 1 | while read LATCH
	        do
	            ${ pkgs.coreutils }/bin/echo -en "_$( ${ pkgs.coreutils }/bin/basename $LATCH | ${ pkgs.coreutils }/bin/cut --bytes 1-4 )" &&
	                ${ pkgs.coreutils }/bin/true
	        done &&
	        ${ pkgs.coreutils }/bin/echo &&
                ${ pkgs.coreutils }/bin/true
        done &&
	${ pkgs.coreutils }/bin/true
) | ${ pkgs.unixtools.column }/bin/column -t -s "_" &&
    ${ pkgs.coreutils }/bin/true
'' ;

crash-pad = structure { root = true ; descriptor = "User Crash Pad" ; constructor-script = "${ pkgs.coreutils }/bin/ln --symbolic $( ${ home }/bin/structure $1)/structure $( ${ pkgs.coreutils }/bin/pwd )/home" ; saltor-script = "${ pkgs.libuuid }/bin/uuidgen " ; } ;

home = structure { descriptor = "User Home Directory" ; constructor-script = ''
( ${ pkgs.coreutils }/bin/cat > .profile <<EOF
export PATH=$PATH:$HOME/bin &&
    export FOOBAR=yes &&
    export KLUDGE_PASSPHRASE_ENTRY_STORE=$( ${ kludge-passphrase-entry-store }/bin/structure $1 ) &&
    ${ kludge-passphrase-entry-program ( dot-gnupg ( private "gpg-private-keys.asc" ) ( private "gpg-ownertrust.asc" ) ( private "gpg2-private-keys.asc" ) ( private "gpg2-ownertrust.asc" ) ) ./uuid.asc.gpg ./uuid.asc }/bin/kludge-passphrase-entry-program &&
    export BOOT_GPGHOME=$( ${ dot-gnupg ( private "gpg-private-keys.asc" ) ( private "gpg-ownertrust.asc" ) ( private "gpg2-private-keys.asc" ) ( private "gpg2-ownertrust.asc" ) }/bin/structure $2 ) &&
    export GPGHOME=\$( ${ dot-gnupg ( boot-secret "gpg-private-keys" { file-name = "gpg-private-keys.asc" ; } ) ( boot-secret "gpg-ownertrust" { file-name = "gpg-ownertrust.asc" ; } ) ( boot-secret "gpg2-private-keys" { file-name = "gpg2-private-keys.asc" ; } ) ( boot-secret "gpg2-ownertrust" { file-name = "gpg2-ownertrust" ; } ) }/bin/structure $2 ) &&
    ${ pkgs.coreutils }/bin/true
EOF
) &&
    ${ pkgs.coreutils }/bin/mkdir bin &&
    ${ pkgs.coreutils }/bin/true
'' ; saltor-script = "${ pkgs.coreutils }/bin/date +%Y%m%d%H --date @$1" ; } ;


in pkgs.mkShell {
    shellHook = ''
        CRASH_PAD=$( ${ crash-pad }/bin/structure ) &&
#            trap "${ destroy-structures }/bin/destroy-structures $CRASH_PAD" EXIT &&
	    export HOME=$CRASH_PAD/structure/home &&
	    cd $HOME &&
	    if [ -f $HOME/.profile ]
	    then
	        source $HOME/.profile &&
		    ${ pkgs.coreutils }/bin/true
	    fi &&
	    ${ investigate-structures }/bin/investigate-structures &&
	    ${ pkgs.coreutils }/bin/true
    '' ;
    buildInputs = [
#        ( scripts.pass "system-secrets" ( dot-gnupg ( boot-secret "gpg-private-keys" ) ( boot-secret "gpg-ownertrust" ) ( boot-secret "gpg2-private-keys" ) ( boot-secret "gpg2-ownertrust" ) ) ( git-fetch "Emory Merryman" "emory.merryman@gmail.com" system.ssh-config "upstream:nextmoose/secrets.git" "320d6d6e-1c95-11eb-832f-e379b175e669" "personal:nextmoose/secrets.git" "320d6d6e-1c95-11eb-832f-e379b175e669" "upstream:nextmoose/secrets.git" ) )
#        ( pass "s3-secrets" ( dot-gnupg ( boot-secret-file "gpg-private-keys" ) ( boot-secret-file "gpg-ownertrust" ) ( boot-secret-file "gpg2-private-keys" ) ( boot-secret-file "gpg2-ownertrust" ) ) ( git-fetch "Emory Merryman" "emory.merryman@gmail.com" system.ssh-config "upstream:nextmoose/secrets.git" "07d63638-1cff-11eb-b2ee-2f9a43a35f1c" "personal:nextmoose/secrets.git" "07d63638-1cff-11eb-b2ee-2f9a43a35f1c" "upstream:nextmoose/secrets.git" ) )
#        ( pass "aws-secrets" ( dot-gnupg ( boot-secret-file "gpg-private-keys" ) ( boot-secret-file "gpg-ownertrust" ) ( boot-secret-file "gpg2-private-keys" ) ( boot-secret-file "gpg2-ownertrust" ) ) ( git-fetch "Emory Merryman" "emory.merryman@gmail.com" system.ssh-config "upstream:nextmoose/secrets.git" "b4fbbe3e-1d02-11eb-b3f7-37d1715385e1" "personal:nextmoose/secrets.git" "b4fbbe3e-1d02-11eb-b3f7-37d1715385e1" "upstream:nextmoose/secrets.git" ) )
#        ( pass "iam-secrets" ( dot-gnupg ( boot-secret-file "gpg-private-keys" ) ( boot-secret-file "gpg-ownertrust" ) ( boot-secret-file "gpg2-private-keys" ) ( boot-secret-file "gpg2-ownertrust" ) ) ( git-fetch "Emory Merryman" "emory.merryman@gmail.com" system.ssh-config "upstream:nextmoose/secrets.git" "3efc85f6-1dde-11eb-985d-df0734ab77d9" "personal:nextmoose/secrets.git" "3efc85f6-1dde-11eb-985d-df0734ab77d9" "upstream:nextmoose/secrets.git" ) )
#	( aws-cli "my-aws" "AKIAYZXVAKILN5GK7UUJ" ( secret-value  ( dot-gnupg ( private "gpg-private-keys.asc" ) ( private "gpg-ownertrust.asc" ) ( private "gpg2-private-keys.asc" ) ( private "gpg2-ownertrust.asc" ) ) ( builtins.fetchGit { url = "https://github.com/nextmoose/secrets.git" ; ref = "3efc85f6-1dde-11eb-985d-df0734ab77d9" ; rev = "99ab11127c09fa112ddeb9376ddc635a318501b5" ; } ) "AKIAYZXVAKILN5GK7UUJ" ) )
	pkgs.jq
	pkgs.s3fs
	pkgs.encfs
	pkgs.gtk2
	pkgs.libcanberra
	pkgs.gtk_engines
	pkgs.gtk2fontsel
#	( gnucash "4d589e82-f96e-4dd6-ace1-d91c08e2a7c4" )
	pkgs.emacs
	investigate-links
	investigate-failure
	investigate-structures
	destroy-structures
	collect-garbage
    ] ;
}