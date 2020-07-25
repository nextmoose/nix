#!/bin/sh

# To add completion for an extension command define a function like this:
__pass_OUT-password_store_extension_complete_COMMAND() {
    COMPREPLY+=($(compgen -W "-o --option" -- ${cur}))
    _pass_OUT_complete_entries 1
}
