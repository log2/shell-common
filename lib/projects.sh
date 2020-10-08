#!/usr/bin/env bash

include "${CALLER_PACKAGE:-"log2/shell-common"}" lib/log.sh

req xmlstarlet

get_version() {
    local vFileBasic="version"
    local vFileMaven="pom.xml"
    local vFileGradle="build.gradle"
    local vFileAngular="package.json"
    local vFileHelm="Chart.yaml"

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
        whine "implement me"
        ((count++))
    fi
    if [ -f "$vFileAngularPath" ]; then
        vFiles="$vFiles'$vFileAngular'"
        whine "implement me"
        ((count++))
    fi
    if [ -f "$vFileHelmPath" ]; then
        vFiles="$vFiles'$vFileHelm'"
        whine "implement me"
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

get_branch() {
    local baseDir=${1:-.}
    git_branch=$(cd "$baseDir" && git rev-parse --abbrev-ref HEAD)
    echo "$git_branch"
}

get_current_tag() {
    local baseDir=${1:-.}
    git_tag=$(cd "$baseDir" && git describe --exact-match --tags)
    echo "$git_tag"
}

tag_exists() {
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
    version=$(get_version "$baseDir")
    local branch
    branch=$(get_branch "$baseDir")

    local snapshotSuffix="-SNAPSHOT"
    local rcSuffix="-rc"

    check_master() {
        local baseDir=$1
        local version=$2
        case "$version" in
            *$snapshotSuffix)
                whine "SNAPSHOT version not allowed in master branch"
                ;;
            *$rcSuffix*)
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
    local remoteHost=$4 # "116325564800.dkr.ecr.eu-central-1.amazonaws.com"

    remoteImage="$remoteHost/$repoName:$remoteTag"
    docker tag "$repoName:$localTag" "$remoteImage"
    docker push "$remoteImage"
}

create_version_tag() {
    local baseDir=${1:-.}
    local version
    version=$(get_version "$baseDir")
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