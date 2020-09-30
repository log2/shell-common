#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
. "${BASHER_ROOT:-$(dirname "$(command -v basher)")/..}/lib/include.${SHELL##*/}"

include "${CALLER_PACKAGE:-"log2/shell-common"}" lib/strings.sh
include "${CALLER_PACKAGE:-"log2/shell-common"}" lib/log.sh

#
# Create $1 as a folder if it does not already exists as a file
#
mkdir_if_not_file()  {
	local dir="$1"
	if [ -f "$dir" ]; then
		log "$(b "$dir") already exists as a file, will not create a same-named folder"
	else
		mkdir -p "$dir"
	fi
}

#
# Finds out size of file or folder $1
#
size() {
	local file_or_folder="$1"
	trim "$(du -d 0 -h "$file_or_folder" | cut -f 1 -)"
}

simple_name() {
	local file_or_folder="$1"
	strip_prefix "$(dirname "$file_or_folder")/" "$file_or_folder"
}

_volume_size_data() {
	local file_or_folder="$1"
	df -h "$file_or_folder" | tail +2
}

_volume_size_component() {
	local volume="$1"
	local component_index="$2"
	local space_information
	read -r -a space_information < <(_volume_size_data "$volume")
	trim "${space_information[$component_index]}"
}

#
# Get volume free space on $1, expressed in human readable format
#
volume_free_space() {
	local volume="$1"
	_volume_size_component "$volume" 3
}

#
# Get volume size on $1, expressed in human readable format
#
volume_size() {
	local volume="$1"
	_volume_size_component "$volume" 1
}

#
# Get volume used space on $1, expressed in human readable format
#
volume_used_space() {
	local volume="$1"
	_volume_size_component "$volume" 2
}
