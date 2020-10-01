#!/usr/bin/env bash

scriptName=$(basename "$0")
scriptVersion=0.1.0-SNAPSHOT

if [[ $DEP_SOURCED == 1  ]]; then 
    >&2 echo "Error invoking '$scriptName' (already sourced)"
    exit 1
fi

if [[ -z $DEP_CALLER_ID ]] ; then
    >&2 echo "Missing variable DEP_CALLER_ID"
    exit 1
fi

>&2 echo -n "Running '$scriptName' version '$scriptVersion'. Checking basher installation... "
basherInitFile="${BASHER_ROOT:-$(dirname "$(command -v basher)")/..}/lib/include.${SHELL##*/}"
if [ -f "$basherInitFile" ]; then
    # shellcheck disable=SC1090,SC1091
    source "$basherInitFile"
    DEP_SOURCED=1
    >&2 echo "OK"
else
    >&2 echo "required basher init script not found" 
    exit 1
fi

checkBlanks() {
    # also check for other unsupported chars?
    for s in "$@"
    do
        if [[ $s = *[[:space:]]* ]] ; then
             >&2 echo "no blanks allowed in parameters/variables"
            exit 1
        fi
    done
}

repoBaseURL=${DEP_REPO_BASE_URL:-"https://github.com"}
callerPath=${DEP_CALLER_PATH:-"basherTemp"}
callerID=$DEP_CALLER_ID
checkBlanks "$callerID" "$repoBaseURL" "$callerPath"

basherInclude() {
    callerPackageName="$packageName-(tag-$packageTag-includedBy-$callerID)"
    if basher list | grep -q "$callerPackageName" && [[ -d "$callerPath/$packageName" ]] ; then
        gitExecute="git --git-dir "$callerPath/$packageName/.git""
        existingTag=$($gitExecute describe --exact-match --tags) || exit 1
        >&2 echo "found existingTag: $existingTag"
        if [[ "$existingTag" != "$packageTag" ]] ; then
            eval "$gitExecute" fetch --all --tags -q
            eval "$gitExecute" checkout -q "tags/$packageTag"
        fi
    else
        [ ! -d "$callerPath" ] && mkdir -p "$callerPath"
        rm -rf "./$callerPath/$packageName"
        git clone --depth 1 --branch "$packageTag" "$repoBaseURL/$packageName" "$callerPath/$packageName" || exit 1
        basher link "$callerPath/$packageName" "$callerPackageName"
    fi

    CALLER_PACKAGE=$callerPackageName include "$callerPackageName" "lib/$scriptName.sh"
}

dep() {
    command=$1
    shift
    case $command in
        include)
            packageName=$1
            packageTag=$2
            scriptName=$3
            if [[ -z $packageName ]] || [[ -z $packageTag ]] || [[ -z $scriptName ]] ; then
                >&2 echo "usage: dep include <packageName> <packageTag> <scriptName>"
                exit 1
            fi
            checkBlanks "$packageName" "$packageTag" "$scriptName"
            local logSubstring="script '$scriptName.sh' tag=$packageTag git repo=$repoBaseURL/$packageName callerID=$callerID callerPath=$callerPath"
            >&2 echo "including $logSubstring"
            basherInclude "$@"
            >&2 echo "inclued $logSubstring"
            ;;
        * ) 
            # implement extensibility
            >&2 echo "usage: dep <command> <options> (currently available commands: [include])"
            exit 1
    esac
}
