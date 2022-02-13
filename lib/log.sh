#!/usr/bin/env bash

if type dep &>/dev/null ; then
    dep include log2/shell-common strings
	dep include log2/shell-common exist
    dep include log2/shell-common styles
else
    include log2/shell-common lib/strings.sh
	include log2/shell-common lib/exist.sh
    include log2/shell-common lib/styles.sh
fi

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

exit_err() {
	local message=("$@")
	emit_log_line
	emit_log_line "[ERROR]"
	emit_log_line "$(as_log "${message[@]}")"
	exit 1
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
	end_log_line_with_color vanilla "${message[@]}"
}

end_log_line_with_color() {
	local color="$1"
	local message=("${@:2}")
	if istty && [ -n "$color" ] && [ "$color" != "vanilla" ]; then
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
