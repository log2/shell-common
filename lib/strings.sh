#!/usr/bin/env bash

#
# Check if second parameter ($2) starts with first parameter ($1)
# Also works when one or both parameters incluce spaces
#
begins_with()
{
    local prefix="$1"
    local string="$2"
    if case "$string" in "$prefix"*) ;; *) false ;; esac then
        true
    else
        false
    fi
}

#
# Remove prefix $1 from $2, if the latter starts with the former
#
strip_prefix()
{
    local prefix="$1"
    local string="$2"
    if begins_with "$prefix" "$string"; then
        local initial_chars
        initial_chars=$((1 + ${#prefix}))
        echo "$string" | cut -c $initial_chars-
    else
        echo "$string"
    fi
}

#
# Strip spaces from the beginning and the end of $1
#
trim()
{
    local message=("$@")
    echo "${message[@]}" | xargs
}
