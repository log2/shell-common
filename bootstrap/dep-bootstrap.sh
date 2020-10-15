#!/usr/bin/env bash
scriptName=dep-bootstrap.sh
scriptVersion=0.2.0-SNAPSHOT
>&2 echo "Running $scriptName version=$scriptVersion"

shellName="${SHELL##*/}"
case $shellName in
    "ash")
        >&2 echo "using fallback shell 'sh' to serve current shell 'ash"
        shellNameFallback="sh"
        ;;
    *)
        shellNameFallback=$shellName
        ;;
esac

basherDir="${BASHER_ROOT:-$HOME/.basher}"
basherExecutable="$basherDir/bin/basher"
basherLocalRepo="$basherDir/repo"
# shellcheck disable=SC2016
rcFileLine1='export PATH="'$(dirname "$basherExecutable")':$PATH"'
# shellcheck disable=SC2016
rcFileLine2='eval "$('$basherExecutable' init - '$shellName')"'

if [[ "$1" == "install" ]] ; then
    if [ -f "$basherExecutable" ]; then
        >&2 echo "Basher executable already present, skipping installation"
    else
        >&2 echo "Basher executable not found, cloning git repo..."
        git clone https://github.com/basherpm/basher.git "$HOME"/.basher
        case $shellNameFallback in
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
        echo "$rcFileLine1" >> "$HOME"/$rcFile
        echo "$rcFileLine2" >> "$HOME"/$rcFile
        >&2 echo "Basher installation completed"
    fi
    exit
fi

if [[ "$DEP_SOURCED" == 1  ]]; then 
    >&2 echo "Error invoking '$scriptName' (already sourced)"
    exit 1
fi

if [ -f "$basherExecutable" ]; then
    >&2 echo "Detected shell=$shellName basher=$basherExecutable"
    if ! command -v basher >/dev/null ; then
        >&2 echo "basher command not available, initializing..."
        eval "$rcFileLine1"
        eval "$rcFileLine2"
    fi
    # shellcheck disable=SC1090
    . "$(dirname "$basherExecutable")/../lib/include.$shellNameFallback"
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
checkBlanks "$repoBaseURL"

dep() {
    command=$1
    if [[ -z $command ]] ; then
        >&2 echo "usage: dep <command> <options> (currently available commands: [include])"
        exit 1
    fi
    shift
    "dep_$command" "$@"
}

dep_include() {
    packageNameTag=$1
    scriptName=$2
    if [[ -z $packageNameTag ]] || [[ -z $scriptName ]] ; then
        >&2 echo "usage: dep include <packageName:packageTag> <scriptName>"
        exit 1
    fi
    checkBlanks "$packageNameTag" "$scriptName"

    local arr
    #shellcheck disable=SC2206
    arr=(${packageNameTag//:/ })
    packageName=${arr[0]}
    packageTag=${arr[1]}

    local logSubstring="script '$scriptName.sh' tag=$packageTag git repo=$repoBaseURL/$packageName local repo=$basherLocalRepo"
    local included=" $packageName-$scriptName "
    >&2 echo "including $logSubstring"
    if [[ $DEP_INCLUDE_ALL = *$included* ]] ; then
        >&2 echo "already included, skipping"
        return
    else
        DEP_INCLUDE_ALL="$DEP_INCLUDE_ALL$included" 
    fi

    versionedPackageName="$packageName-$packageTag"
    localPackagePath="$basherLocalRepo/$packageName/$packageTag"
    if [[ $packageTag != *"-SNAPSHOT" ]] && [[ -d "$localPackagePath" ]] && $basherExecutable list | grep -q "$versionedPackageName" ; then
        >&2 echo "found existing local copy of: '$versionedPackageName'"
        gitExecute="git --git-dir "$localPackagePath/.git""
        existingTag=$($gitExecute describe --exact-match --tags) || exit 1
        if [[ "$existingTag" != "$packageTag" ]] ; then
             >&2 echo "unexpected local tag found: '$existingTag'. Expected: '$packageTag'"
             exit 1
        fi
    else
        $basherExecutable uninstall "$versionedPackageName" 1>&2
        [ ! -d "$localPackagePath" ] && mkdir -p "$localPackagePath"
        rm -rf "$localPackagePath"
        git -c advice.detachedHead=false clone --depth 1 --branch "$packageTag" "$repoBaseURL/$packageName" "$localPackagePath" || exit 1
        $basherExecutable link "$localPackagePath" "$versionedPackageName" || exit 1
    fi

    CALLER_PACKAGE=$versionedPackageName include "$versionedPackageName" "lib/$scriptName.sh" || exit 1

    >&2 echo "inclued $logSubstring"
}
