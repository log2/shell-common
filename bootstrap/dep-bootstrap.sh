#!/usr/bin/env bash

basherExecutable="${BASHER_ROOT:-$HOME/.basher}/bin/basher"
shellName="${SHELL##*/}"

if [[ $1 == "install" ]] ; then
    if [ -f "$basherExecutable" ]; then
        >&2 echo "Basher executable already present, skipping installation"
    else
        >&2 echo "Basher executable not found, cloning git repo..."
        git clone https://github.com/basherpm/basher.git "$HOME"/.basher
        case $shellName in
            "bash")
                rcFile=".bashrc"
                ;;
            "dash")
                rcFile=".bashrc"
                ;;
            "sh")
                rcFile=".profile"
                ;;
            "zsh")
                rcFile=".zshrc"
                ;;
            *)
                >&2 echo "Unsupported shell $shellName"
                exit 1
                ;;
        esac
        # shellcheck disable=SC2016
        rcFileLine1='export PATH="'$(dirname "$basherExecutable")':$PATH"'
        echo "$rcFileLine1" >> "$HOME"/$rcFile
        # shellcheck disable=SC2016
        rcFileLine2='eval "$('$basherExecutable' init - '$shellName')"'
        echo "$rcFileLine2" >> "$HOME"/$rcFile
        >&2 echo "Basher installation completed"
    fi
    exit
fi

scriptName=$(basename "${BASH_SOURCE[0]}")
scriptVersion=0.1.0-SNAPSHOT
>&2 echo "Running $scriptName version=$scriptVersion"

if [[ $DEP_SOURCED == 1  ]]; then 
    >&2 echo "Error invoking '$scriptName' (already sourced)"
    exit 1
fi

if [[ -z $DEP_CALLER_ID ]] ; then
    >&2 echo "Missing variable DEP_CALLER_ID"
    exit 1
fi

if [ -f "$basherExecutable" ]; then
    >&2 echo "Detected shell=$shellName basher=$basherExecutable"
    # shellcheck disable=SC1090
    source "$(dirname "$basherExecutable")/../lib/include.$shellName"
    DEP_SOURCED=1
else
    >&2 echo "Unable to find basher executable, try installing using command: '$scriptName install'"
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

dep() {
    echo "$PATH"
    tail -n 5 "$HOME"/.bashrc
    which basher

    command=$1
    if [[ -z $command ]] ; then
        >&2 echo "usage: dep <command> <options> (currently available commands: [include])"
        exit 1
    fi
    shift
    "dep_$command" "$@"
}

dep_include() {
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

    callerPackageName="$packageName-(tag-$packageTag-includedBy-$callerID)"
    if $basherExecutable list | grep -q "$callerPackageName" && [[ -d "$callerPath/$packageName" ]] ; then
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
        $basherExecutable link "$callerPath/$packageName" "$callerPackageName" || exit 1
    fi

    CALLER_PACKAGE=$callerPackageName include "$callerPackageName" "lib/$scriptName.sh" || exit 1

    >&2 echo "inclued $logSubstring"
}
