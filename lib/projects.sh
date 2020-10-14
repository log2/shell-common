#!/usr/bin/env bash

include "${CALLER_PACKAGE:-"log2/shell-common"}" lib/log.sh

# req xmlstarlet

project_version() {
    local vFileBasic="version"
    local vFileMaven="pom.xml"
    local vFileGradle="app/versions.gradle"
    local vFileAngular="package.json"
    local vFileHelm="chart/Chart.yaml"

    local baseDir=${1:-.}
    log "searching version file in path: $baseDir"

    local vFileBasicPath="$baseDir/$vFileBasic"
    local vFileMavenPath="$baseDir/$vFileMaven"
    local vFileGradlePath="$baseDir/$vFileGradle"
    local vFileAngularPath="$baseDir/$vFileAngular"
    local vFileHelmPath="$baseDir/$vFileHelm"

    local vFiles=""
    local version=""
    local count=0
    if [ -f "$vFileBasicPath" ]; then
        vFiles="$vFiles'$vFileBasic'"
        version=$(cat "$vFileBasicPath")
        ((count++))
    fi
    if [ -f "$vFileMavenPath" ]; then
        vFiles="$vFiles'$vFileMaven'"
        version=$(xmlstarlet sel -N x=http://maven.apache.org/POM/4.0.0 -t -m "/x:project/x:version" -v . "$vFileMavenPath")
        ((count++))
    fi
    if [ -f "$vFileGradlePath" ]; then
        vFiles="$vFiles'$vFileGradle'"
        version=$(grep "commonVersion" "$vFileGradlePath" | sed 's/.*"\(.*\)".*/\1/')
        ((count++))
    fi
    if [ -f "$vFileAngularPath" ]; then
        vFiles="$vFiles'$vFileAngular'"
        version=$(jq '.version'<"$vFileAngularPath")
        ((count++))
    fi
    if [ -f "$vFileHelmPath" ]; then
        vFiles="$vFiles'$vFileHelm'"
        version=$(yq r - "version"<"$vFileHelmPath")
        ((count++))
    fi
    if [ "$count" = 0 ]; then
        whine "no version file found"
    elif [ "$count" -gt 1 ]; then
        whine "too much ($count) version files found: $vFiles"
    fi
    log "found version='$version' in file: $vFiles"
    echo "$version"
}

unique_snapshot_version() {
    local version="$1"
    local id="$2"
    if [[ "$version" != *"-SNAPSHOT" ]] ; then 
        whine "invalid version: $version"
    fi
    # shellcheck disable=SC2001
    bareVersion=${version%-SNAPSHOT}
    echo "$bareVersion-$id-SNAPSHOT"
}

git_commit() {
    local baseDir=${1:-.}
    commitId=$(cd "$baseDir" && git rev-parse HEAD)
    echo "$commitId"
}

git_branch() {
    local baseDir=${1:-.}
    commitId=$(git_commit "$baseDir")
    local branch
    branch=$(cd "$baseDir" && git rev-parse --abbrev-ref HEAD)
    if [[ "$branch" = "HEAD" ]] ; then
        #FIXME possible problems if more than one branch found
        branch=$(cd "$baseDir" && git for-each-ref --format='%(objectname) %(refname:short)' refs | awk "/^$commitId/ {print \$2}")
        branch=${branch##origin/}
    fi
    echo "$branch"
}

git_current_tag() {
    local baseDir=${1:-.}
    git_tag=$(cd "$baseDir" && git describe --exact-match --tags)
    echo "$git_tag"
}

git_tag_exists() {
    local baseDir=$1
    local tag=$2
    (cd "$baseDir" && git tag | grep "^$tag$" 1>&2 )
}

get_patch_number() {
    version=$1
    echo "${version##*.}"
}

check_version() {
    local baseDir=${1:-.}
    local version
    version=$(project_version "$baseDir")
    local branch
    branch=$(git_branch "$baseDir")

    local snapshotSuffix="-SNAPSHOT"
    local rcKey="-rc"

    check_master() {
        local baseDir=$1
        local version=$2
        case "$version" in
            *$snapshotSuffix)
                whine "SNAPSHOT version not allowed in master branch"
                ;;
            *$rcKey*)
                whine "rc version not allowed in master branch"
                ;;
            *)
                if tag_exists "$baseDir" "$version" ; then
                    whine "tag $version already found"
                fi
                ;;
        esac
    }

    check_develop() {
        case "$1" in
            *$snapshotSuffix)
                strippedSnapshot=${1%%$snapshotSuffix}
                patchNumber=$(get_patch_number "$strippedSnapshot")
                if [[ $patchNumber != 0 ]] ; then
                    whine "non-zero patch version not allowed in develop/feature branch"
                fi
                ;;
            *)
                whine "non SNAPSHOT version not allowed in develop/feature branch"
                ;;
        esac
    }

    log "checking version $version in branch $branch"
    case "$branch" in
        "master")
            check_master "$baseDir" "$version"
            ;;
        "develop" | "feature/"*)
            check_develop "$version"
            ;;
        *)
            whine "unsupported branch $branch"
    esac

    echo "$version"
}

docker_push() {
    local repoName=$1
    local localTag=$2
    local remoteTag=$3
    local remoteHost=$4

    remoteImage="$remoteHost/$repoName:$remoteTag"
    docker tag "$repoName:$localTag" "$remoteImage"
    docker push "$remoteImage"
}

create_version_tag() {
    local baseDir=${1:-.}
    local version
    version=$(project_version "$baseDir")
    (
        cd "$baseDir" || exit 1
        if [ -z "$(git status --porcelain)" ]; then 
            git tag "$version"
            log "added tag: $version"
        else
            whine "uncommitted changes found"
        fi
    )    
}
