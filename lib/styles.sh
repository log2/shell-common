#!/usr/bin/env bash

if type dep &>/dev/null ; then
    dep include log2/shell-common exist
else
    include log2/shell-common lib/exist.sh
fi

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
			#FIXME seems to be not working properly (try using getaf for storing default color)
			# echo "${message[@]}"
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

ab() {
    # Accent + bold
    green "$(b "$*")"
}
