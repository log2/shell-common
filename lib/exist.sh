#!/usr/bin/env bash

wh()
{
    local command_name="$1"
    command -v "$command_name"
}

exists()
{
    local command="$1"
    wh "$command" >/dev/null 2>&1
}

source_if_exists()
{
    local whatToSource="$1"
    # shellcheck disable=SC1090
    [ -e "$whatToSource" ] && . "$whatToSource"
}
