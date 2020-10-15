#!/usr/bin/env bash

# shellcheck disable=SC1090
source "$HOME"/.basher/lib/include.zsh
basher uninstall temp/temp-0.0.0
basher link . temp/temp-0.0.0
localRepoDir="$HOME"/.basher/repo/temp/temp/0.0.0
rm -rf "$localRepoDir"
mkdir -p "$localRepoDir"
cp -rf ./.git "$localRepoDir"
cp -rf ./lib "$localRepoDir"
(cd "$localRepoDir" && git tag 0.0.0)
CALLER_PACKAGE=temp/temp-0.0.0 include temp/temp-0.0.0 lib/projects.sh

target="$HOME/_all/git/ecomind/eye4task-coturn"

version=$(check_version "$target")
echo "x"

tag_exists "$target" "$version"

echo "y"
get_branch "$target"

# docker_push eye4task-coturn commitId-xenial myTag 116325564800.dkr.ecr.eu-central-1.amazonaws.com
