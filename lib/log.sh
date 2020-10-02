#!/usr/bin/env bash

include "${CALLER_PACKAGE:-"log2/shell-common"}" lib/strings.sh

wh() {
	local command_name="$1"
	command -v "$command_name" 
} 

get_version() {
	local command_name="$1"
	local double_dash_version
	double_dash_version="$("$command_name" --version 2>/dev/null | head -n 1)"
	if [ -z "$double_dash_version" ]; then
		"$command_name" version 2>/dev/null | head -n 1
	else
		echo "$double_dash_version"
	fi
} 

exists() {
	local command="$1"
	wh "$command" >/dev/null 2>&1
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

LOG_ON_STDERR=true

is_log_on_stderr() {
	[ -n "$LOG_ON_STDERR" ]
}

simple_name() {
	local file="$1"
	strip_prefix "$(dirname "$file")/" "$file"
}

as_log() {
	local message=("$@")
    echo "$(date +%FT%T%z) - $(simple_name "$0") - ${message[*]}"
}

emit_log() {
	local message=("$@")
	if is_log_on_stderr ; then
		printf "%b" "${message[@]}" >&2
	else
		printf "%b" "${message[@]}"
	fi
}

emit_log_line() {
	local line=("$@")
	if is_log_on_stderr ; then
		echo "${line[@]}" >&2
	else
		echo "${line[@]}"
	fi
}

log() {
	local message=("$@")
	emit_log_line "$(as_log "${message[@]}")"
}

start_log_line() {
	local message=("$@")
	local line
	line="$(printf "%b" "$(as_log "${message[@]}") ... ")"
	emit_log "$line"
}

end_log_line() {
	local message=("$@")
	end_log_line_with_color green "${message[@]}"
}

end_log_line_with_color() {
	local color="$1"
	local message=("${@:2}")
	if istty ; then 
		emit_log_line "$("$color" "$(b "${message[@]}")")"
	else
		emit_log_line "${message[@]}"
	fi
}

end_log_line_err() {
	local message=("$@")
	if istty_err ; then
		red "$(b "${message[@]}")" >&2
	else
		echo "${message[@]}" >&2
	fi
}

logtty() {
	local message=("$@")
	if istty ; then log "${message[@]}" ; fi
}

prepare_styling() {
	if exists tput ; then
		STYLE_BOLD="$(tput bold)"
		STYLE_OFF="$(tput sgr0)"
		COLOR_NORMAL="$(tput setaf 7)"
		# COLOR_BLACK="$(tput setaf 0)"
		COLOR_RED="$(tput setaf 1)"
		COLOR_GREEN="$(tput setaf 2)"
		COLOR_YELLOW="$(tput setaf 3)"
		COLOR_BLUE="$(tput setaf 4)"

		replace_style_off() {
			local message=("${@:2}")
			local color_prefix="$1"
			echo "${message//${STYLE_OFF}/${STYLE_OFF}${color_prefix}}"
		}
		b() {
			local message=("$@")
			echo "$STYLE_BOLD${message[*]}$STYLE_OFF"
		}
		wrap_color() {
			local color_prefix="$1"
			local message=("${@:2}")
			echo "$color_prefix$(replace_style_off "$color_prefix" "${message[@]}")$COLOR_NORMAL"
		}
		red() {
			local message=("$@")
			wrap_color "$COLOR_RED" "${message[@]}"
		}
		green() {
			local message=("$@")
			wrap_color "$COLOR_GREEN" "${message[@]}"
		}
		yellow() {
			local message=("$@")
			wrap_color "$COLOR_YELLOW" "${message[@]}"
		}
		blue() {
			local message=("$@")
			wrap_color "$COLOR_BLUE" "${message[@]}"
		}

		ansi() { 
			local ansi_code="$1"
			local message=("${@:2}")
			printf "%b" "\e[${ansi_code}m${message[*]}\e[0m" 
		}
		# bold() { 
		# 	local message=("$@")
		# 	ansi 1 "${message[@]}" 
		# }
		i() { 
			local message=("$@")
			ansi 3 "${message[@]}" 
		}
		u() { 
			local message=("$@")
			ansi 4 "${message[@]}" 
		}
		st() { 
			local message=("$@")
			ansi 9 "${message[@]}" 
		}		
	else
		logtty "Program tput not found, text styling will be disabled"
		vanilla() {
			local message=("$@")
			echo "${message[@]}"
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
	local message=("$@")
	as_log "$(red "${message[@]}")" 
} >&2

warn() {
	local message=("$@")
	as_log "$(yellow "${message[@]}")"
} >&2

whine() {
	local cause="$1"
	local code="${2:-1}"
	err "$cause"
	exit "$code"
}

req1() {
	local program="$1"
    local version="$2"
	start_log_line "Checking for existence of required program $(b "$program")"
	if exists "$program" ; then
        if [[ "$version" = "--no-version" ]] ; then
            version="na"
        else
            version="$(get_version "$program")"
        fi
		end_log_line "program $(b "$program") found at $(b "$(wh "$program")") (version: $(b  $version))!"
	else
		end_log_line_err "needed program $(b "$program") is nowhere to be found!"
		end_log_line_err "Please try installing $(b "$program") via the following command, which may or may not work:"
		b brew install "$program" >&2
		whine "Cowardly refusing to execute this script without the required program. Have a nice day!"
	fi
}

req() {
    # FIXME use collect-then-check pattern
	log "Performing pre-boot script sanity checks..."
	for p in "$@"; do req1 "${p}" ; done
	log "$(green "Script sanity checks completed successfully, current script $(b "$0") can start!")"
	log
}

req_no_ver() {
    # FIXME use collect-then-check pattern
	log "Performing pre-boot script sanity checks..."
	for p in "$@"; do req1 "${p}" "--no-version"; done
	log "$(green "Script sanity checks completed successfully, current script $(b "$0") can start!")"
	log
}
