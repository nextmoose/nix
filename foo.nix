pkgs : {
    foo = ''
        ${ pkgs.coreutils }/bin/echo FOO &&
	    ${ pkgs.coreutils }/bin/true
    '' ;
}