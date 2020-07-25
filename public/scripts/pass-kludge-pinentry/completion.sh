#!/bin/sh

# To add completion for an extension command define a function like this:
__pass_dslwwnw3v74dl39d5sz2zy488qbs6p57-password_store_extension_complete_<COMMAND>() {
    COMPREPLY+=($(compgen -W "-o --option" -- ${cur}))
    _pass_dslwwnw3v74dl39d5sz2zy488qbs6p57-pass_complete_entries 1
}
