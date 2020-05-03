#!/usr/bin/env bash

#
# Check if second parameter ($2) starts with first parameter ($1)
# Also works when one or both parameters incluce spaces
#
begins_with() {
	if [[ "$2" == "$1"* ]]; then
		true
	else
		false
	fi
}

#
# Remove prefix $1 from $2, if the latter starts with the former
#
strip_prefix() {
	if begins_with "$1" "$2" ;  then
		local initial_chars
		initial_chars=$(( 1 + ${#1} ))
		echo "$2" | cut -c $initial_chars-
	else
		echo "$2"
	fi
}

#
# Create $1 as a folder if it does not already exists as a file
mkdir_if_not_file()  {
	if [ -f "$1" ]; then
		log "$(b "$1") already exists as a file, will not create a same-named folder"
	else
		mkdir -p "$1"
	fi
}

#
# Strip spaces from the beginning and the end of $1
#
trim() {
	echo "$*" | xargs
}

#
# Finds out size of file or folder $1
#
size() {
	trim "$(du -d 0 -h "$1" | cut -f 1 -)"
}

exists() {
	which "$1" >/dev/null 2>&1
}

istty() {
	if [ -t 1 ]; then
		return 0
	else
		return 1
	fi
}

istty_err() {
	if [ -t 2 ]; then
		return 0
	else
		return 1
	fi
}

# as_log() {
# 	echo "$*"
# }

simple_name() {
	strip_prefix "$(dirname "$1")/" "$1"
}

as_log() {
    echo "$(date +%FT%T%z) - $(simple_name "$0") - $*"
}

log() {
	as_log "$*"
}

start_log_line() {
	printf "%b" "$(as_log "$*") ... "
}

end_log_line() {
	end_log_line_with_color green "$@"
}

end_log_line_with_color() {
	if istty ; then 
		"$1" "$(b "${@:2}")"
	else
		echo "${@:2}"
	fi
}

end_log_line_err() {
	if istty_err ; then
		red "$(b "$@")" >&2
	else
		echo "$@" >&2
	fi
}

logtty() {
	if istty ; then log "$*" ; fi
}

prepare_styling() {
	if exists tput ; then
		STYLE_BOLD="$(tput bold)"
		STYLE_OFF="$(tput sgr0)"
		COLOR_NORMAL="$(tput setaf 7)"
		COLOR_BLACK="$(tput setaf 0)"
		COLOR_RED="$(tput setaf 1)"
		COLOR_GREEN="$(tput setaf 2)"
		COLOR_YELLOW="$(tput setaf 3)"
		COLOR_BLUE="$(tput setaf 4)"

		replace_style_off() {
			echo "${2//${STYLE_OFF}/${STYLE_OFF}${1}}"
		}
		b() {
			echo "$STYLE_BOLD$*$STYLE_OFF"
		}
		wrap_color() {
			echo "$1$(replace_style_off "$1" "${@:2}")$COLOR_NORMAL"
		}
		red() {
			wrap_color "$COLOR_RED" "$*"
		}
		green() {
			wrap_color "$COLOR_GREEN" "$*"
		}
		yellow() {
			wrap_color "$COLOR_YELLOW" "$*"
		}
		blue() {
			wrap_color "$COLOR_BLUE" "$*"
		}
	else
		logtty "Program tput not found, text styling will be disabled"
		vanilla() {
			echo "$*"
		}
		alias b=vanilla
		alias red=vanilla
		alias green=vanilla
		alias yellow=vanilla
		alias blue=vanilla
	fi
}

prepare_styling


err() {
	as_log "$(red "$*")" >&2
}

whine() {
	err "$*"
	exit "${2:-1}"
}

req1() {
	start_log_line "Checking for existence of required program $(b "$1")"
	if exists "$1" ; then
		end_log_line "program $(b "$1") found at $(b "$(which "$1")")!"
	else
		end_log_line_err "needed program $(b "$1") is nowhere to be found!"
		end_log_line_err "Could not find required program $(b "$1")" >&2
		end_log_line_err "Please try installing $(b "$1") via the following command, which may or may not work:" >&2
		b brew install "$1" >&2
		whine "Cowardly refusing to execute this script without the required program. Have a nice day!"
	fi
}

req() {
	log "Performing pre-boot script sanity checks..."
	for p in "$@"; do req1 "${p}" ; done
	log "$(green "Script sanity checks completed successfully, current script $(b "$0") can start!")"
	log
}

volume_size_data() {
	df -h "$1"|tail +2
}

#
# Get volume free space on $1, expressed in human readable format
#
volume_free_space() {
	local space_information
	read -r -a space_information < <(volume_size_data "$1")
	trim "${space_information[3]}"
}

#
# Get volume size on $1, expressed in human readable format
#
volume_size() {
	local space_information
	read -r -a space_information < <(volume_size_data "$1")
	trim "${space_information[1]}"
}

#
# Get volume used space on $1, expressed in human readable format
#
volume_used_space() {
	local space_information
	read -r -a space_information < <(volume_size_data "$1")
	trim "${space_information[2]}"
}
