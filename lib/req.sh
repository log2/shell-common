#!/usr/bin/env bash

if type dep &>/dev/null ; then
    dep include log2/shell-common exist
else
    include log2/shell-common lib/exist.sh
fi

if type dep &>/dev/null ; then
    dep include log2/shell-common log
else
    include log2/shell-common lib/log.sh
fi

if type dep &>/dev/null ; then
    dep include log2/shell-common asdf
else
    include log2/shell-common lib/asdf.sh
fi

get_version() {
	local command_name="$1"
	local result
	if ! result="$(_get_version "$command_name")"; then
		exit_err "$result"
	else
		echo "$result"
	fi
}

_get_version() {
	local command_name="$1"
	if commandOutput=$($command_name --version 2>/dev/null) ; then
		:
	elif commandOutput=$($command_name version 2>/dev/null) ; then
		:
	else
		echo "get_version failed"
		return 1
	fi
	if [ -n "$commandOutput" ]; then
		while IFS= read -r line; do
			if [[ "$line" != "" ]] ; then
				trim "$line"
				break
			fi
		done <<< "$commandOutput"
	else
		echo "get_version has no output"
		return 1
	fi
}

_VERSION_NO_CHECK="-"
_VERSION_ANY="x"
_VERSION_ANY_VIA_ASDF_IF_AVAILABLE="asdf"

_req_giveup() {
	whine "Cowardly refusing to execute this script without the required program. Have a nice day!"
}

_suggest_and_exit() {
	local program="$1"
	emit_log_line "Please try installing $(b "$program") via the following command, which may or may not work:"
	if exists brew; then
		b brew install "$program" >&2
	elif exists apt; then
		b apt install "$program" >&2
	elif exists apk; then
		b apk add "$program" >&2
	elif exists linuxbrew; then
		b linuxbrew install "$program" >&2
	elif exists yum; then
		b yum install "$program" >&2
	else
		i "Can't find a package manager to install $(b "$program")" >&2
	fi
	_req_giveup
}

_describe_program_and_versionm() {
	local program="$1"
	local version="$2"
	echo "$(ab "$(wh "$program")") (version: $(ab "$version"))"
}

_req1_without_asdf() {
	local program="$1"
    local versionPolicy="$2"
	start_log_line "Checking $(ab "$program")"
	if [ "$versionPolicy" = "$_VERSION_NO_CHECK" ] || [ "$versionPolicy" = "$_VERSION_ANY" ]; then
		if exists "$program" ; then
			if [ "$versionPolicy" = "$_VERSION_NO_CHECK" ] ; then
				version="n/a"
			elif ! version=$(get_version "$program") ; then
				exit_err "can't get version of $(ab "$program") (try with $(b "req_no_ver"))"
			fi
			end_log_line "found at $(_describe_program_and_versionm "$program" "$version")!"
		else
			end_log_line_err "can't find $(ab "$program"). Also, $(b "asdf") is not available."
			_suggest_and_exit "$program"
		fi
	else
		end_log_line "failed"
		whine "Version check is not supported without asdf"
	fi
}

_describe_version() {
	local versionPolicy="$1"
	if [ "$versionPolicy" = "" ]; then
		echo " [any]"
	else
		echo " [version $(ab "$versionPolicy*")]"
	fi
}

_req1_with_asdf_inner_on_new_line() {
	local program="$1"
    local versionPolicy="$2"
    local package="$3"
	local versionPolicyDescription="$(_describe_version "$versionPolicy")"
	start_log_line "Checking $(ab "$program")$versionPolicyDescription via asdf"
	_req1_with_asdf_inner "$program" "$versionPolicy" "$package"
}

_req1_with_asdf_inner() {
	local program="$1"
    local versionPolicy="$2"
    local package="$3"
	pluginName="$(_derive_asdf_plugin_name "$program" "$package")"
	emit_log "plugin $(ab "$pluginName"), "
	if ! _asdf_has_plugin "$pluginName"; then
		emit_log "installing, "
		if ! _asdf_add_plugin "$pluginName" &>/dev/null; then
			emit_log "$(yellow "failed"), "
			if exists "$program"; then
				end_log_line "using $(_describe_program_and_versionm "$program" "$(_get_version "$program")")"
				return 0
			else
				end_log_line_err "can't find $(ab "$program")"
				_suggest_and_exit "$program"
			fi
		fi
    fi
	emit_log "searching for version, "
	local version="$(_asdf_find_latest "$pluginName" "$versionPolicy")"
	if [ -z "$version" ]; then
		end_log_line_err "can't find a suitable version!"
		_req_giveup
	fi
	emit_log "found $(ab "$version"), "
	if _asdf_version_is_installed "$pluginName" "$version"; then
		:
	else
		emit_log "updating, "
		_asdf_update "$pluginName"
		emit_log "installing version, "
		if _asdf_install "$pluginName" "$version"; then
			:
		else
			end_log_line_err "failed!"
			_req_giveup
		fi
    fi
	emit_log "setting shell, "
	if _asdf_set_shell_version "$pluginName" "$version"; then
		end_log_line "done!"
	else
		end_log_line_err "failed!"
		_req_giveup
	fi
}

_is_shim() {
	local program="$1"
	if exists "$program" && [[ "$(wh "$program")" == $HOME/.asdf/shims/* ]]; then
		return 0
	else
		return 1
	fi
}

_req1_with_asdf() {
	local program="$1"
    local versionPolicy="$2"
	local package="$3"
	if [ "$versionPolicy" = "$_VERSION_NO_CHECK" ] || [ "$versionPolicy" = "$_VERSION_ANY" ]; then
		start_log_line "Checking $(ab "$program")"
		if _is_shim "$program"; then
			emit_log "$(i "it's a shim"), using $(b asdf), "
			# Program not found, using asdf to install it (using latest version, since no version was specified)
			_req1_with_asdf_inner "$program"
		elif exists "$program" ; then
			if [ "$versionPolicy" = "$_VERSION_NO_CHECK" ] ; then
				version="n/a"
			elif ! version=$(_get_version "$program") ; then
				emit_log "not found, using $(b asdf), "
				# Program not found, using asdf to install it (using latest version, since no version was specified)
				if _req1_with_asdf_inner "$program" "" "$package"; then
					return 0
				else
					return 1
				fi
			fi
			end_log_line "found at $(_describe_program_and_versionm "$program" "$version") !"
		else
			emit_log "not found, using $(b asdf), "
			# Program not found, using asdf to install it (using latest version, since no version was specified)
			_req1_with_asdf_inner "$program" "" "$package"
		fi
	elif [ "$versionPolicy" = "$_VERSION_ANY_VIA_ASDF_IF_AVAILABLE" ]; then
		# Program not found, using asdf to install it (using latest version, since no version was specified)
		_req1_with_asdf_inner_on_new_line "$program" "" "$package"
	else
		# Search for latest version of program using asdf
		_req1_with_asdf_inner_on_new_line "$program" "$versionPolicy" "$package"
	fi
}

_req1() {
	local program="$1"
    local versionPolicy="$2"
    local package="$3"
	if has_asdf; then
		_req1_with_asdf "$program" "$versionPolicy" "$package"
	else
		_req1_without_asdf "$program" "$versionPolicy"
	fi
}

_req(){
	if [[ $REQ_CHECKED = 1 ]] ; then
		exit_err "pre-boot script sanity checks already done, please define all requirements (i.e. all $(b req), $(b req_no_ver), and $(b req_ver) calls) before calling $(b req_check)"
	fi
    programName="$1"
    versionPolicy="$2"
	package="$3"
	if [[ $_REQ_INCLUDED = *" $programName:"* ]] ; then
		local includedPart=${_REQ_INCLUDED#*" $programName:"}
		local includedValue=${includedPart%%" "*}
		if [[ $includedValue != "$versionPolicy" ]] ; then
			exit_err "Found included value with versionPolicy=$includedValue"
		fi
		if [ -n "$_REQ_VERBOSE" ] ; then
	    	log "Found req for program '$programName', versionPolicy=$includedValue (already present)"
		fi
	else
		_REQ_INCLUDED="$_REQ_INCLUDED $programName:$versionPolicy:$package"
		if [ -n "$_REQ_VERBOSE" ] ; then
	    	log "Found req for program '$programName', versionPolicy=$versionPolicy, package=$package"
		fi
	fi
}

req() {
	# Behaviour:
	# - without asdf: if program is already installed, use it and print version if available, otherwise fail
	# - without asdf: if program is already installed, use it, otherwise try to install its latest version using asdf
	for p in "$@"; do _req "${p}" "$_VERSION_ANY" ; done
}

req_no_ver() {
	# Behaviour:
	# - without asdf: if program is already installed, use it (without calling it to get the version), otherwise fail
	# - with asdf: if program is already installed, use it (without calling it to get the version), otherwise try to install its latest version using asdf
	for p in "$@"; do _req "${p}" "$_VERSION_NO_CHECK" ; done
}

req_ver() {
	# Behaviour:
	# - without asdf: fail
	# - with asdf: try to install its latest matching version using asdf, otherwise fail
	local program="$1"
	local versionSpec="${2:-$_VERSION_ANY_VIA_ASDF_IF_AVAILABLE}"
	local package="${3}"
	_req "$program" "$versionSpec" "$package"
}

req_check() {
	REQ_CHECKED=1
	log "Performing pre-boot script sanity checks..."
	for entry in $_REQ_INCLUDED
	do
		local program=${entry%%:*}
		local secondPart=${entry#*:}
		local versionPolicy=${secondPart%%:*}
		local package=${secondPart##*:}
		_req1 "$program" "$versionPolicy" "$package"
	done
	log "$(green "Script sanity checks completed successfully, current script $(ab "$0") can start!")"
}