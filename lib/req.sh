#!/usr/bin/env bash

if type dep &>/dev/null; then
    dep include log2/shell-common exist
    dep include log2/shell-common log
    dep include log2/shell-common files
    dep include log2/shell-common asdf
    dep include log2/shell-common strings
else
    include log2/shell-common lib/exist.sh
    include log2/shell-common lib/log.sh
    include log2/shell-common lib/files.sh
    include log2/shell-common lib/asdf.sh
    include log2/shell-common lib/strings.sh
fi

_get_version()
{
    local command_name="$1"
    if commandOutput=$($command_name --version 2>/dev/null); then
        :
    elif commandOutput=$($command_name version 2>/dev/null); then
        :
    else
        echo "get_version failed"
        return 1
    fi
    if [ -n "$commandOutput" ]; then
        while IFS= read -r line; do
            if [[ "$line" != "" ]]; then
                trim "$line"
                break
            fi
        done <<<"$commandOutput"
    else
        echo "get_version has no output"
        return 1
    fi
}

get_version()
{
    local command_name="$1"
    local result
    if ! result="$(_get_version "$command_name")"; then
        exit_err "$result"
    else
        echo "$result"
    fi
}

_VERSION_NO_CHECK="-"
_VERSION_ANY="x"
_VERSION_ANY_VIA_ASDF_IF_AVAILABLE="asdf"

_reqAbortMarker="ABORTED"

_suggest_install()
{
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
}

_describe_program_and_version()
{
    local program="$1"
    local version="$2"
    echo "$(ab "$(tildify "$(wh "$program")")") (version: $(ab "$version"))"
}

_asdf()
{
    b asdf
}

_req1_without_asdf()
{
    local program="$1"
    local versionPolicy="$2"
    emit_log "Checking $(ab "$program") ... "
    if [ "$versionPolicy" != "$_VERSION_NO_CHECK" ] && [ "$versionPolicy" != "$_VERSION_ANY" ]; then
        emit_log "no $(_asdf) (but required), just checking existence, "
    fi
    if exists "$program"; then
        local version
        if [ "$versionPolicy" = "$_VERSION_ANY" ]; then
            if ! version=$(_get_version "$program"); then
                end_log_line_err "can't get version of $(ab "$program") - $(ab "$version") (use $(b "req_no_ver") to disable this check)"
                return 1
            fi
        elif [ "$versionPolicy" = "$_VERSION_NO_CHECK" ]; then
            version="$(i "n/a")"
        else
            version="$(i "skipped")"
        fi
        end_log_line "found at $(_describe_program_and_version "$program" "$version")."
    else
        end_log_line_err "can't find $(ab "$program"). Also, $(_asdf) is not available."
        _suggest_install "$program"
        return 1
    fi
}

_describe_version()
{
    local versionPolicy="$1"
    if [ "$versionPolicy" = "" ]; then
        echo " [any]"
    else
        echo " [version $(ab "$versionPolicy*")]"
    fi
}

_req1_with_asdf_inner_on_new_line()
{
    local program="$1"
    local versionPolicy="$2"
    local package="$3"
    local versionPolicyDescription
    versionPolicyDescription="$(_describe_version "$versionPolicy")"
    emit_log "Checking $(ab "$program")$versionPolicyDescription via $(_asdf) ... "
    _req1_with_asdf_inner "$program" "$versionPolicy" "$package"
}

_req1_with_asdf_inner()
{
    local program="$1"
    local versionPolicy="${2:-}"
    local package="${3:-}"
    pluginName="$(_derive_asdf_plugin_name "$program" "$package")"
    emit_log "plugin $(ab "$pluginName"), "
    if ! _asdf_has_plugin "$pluginName"; then
        emit_log "installing, "
        if ! _asdf_add_plugin "$pluginName" &>/dev/null; then
            emit_log "$(yellow "failed"), "
            if exists "$program"; then
                end_log_line "using $(_describe_program_and_version "$program" "$(_get_version "$program")")"
                return 0
            else
                end_log_line_err "can't find $(ab "$program")"
                _suggest_install "$program"
                return 1
            fi
        fi
    fi
    emit_log "searching for version, "
    local version
    version="$(_asdf_find_latest "$pluginName" "$versionPolicy")"
    if [ -z "$version" ]; then
        end_log_line_err "can't find a suitable version!"
        return 1
    fi
    emit_log "found $(ab "$version"), "
    if ! _asdf_version_is_installed "$pluginName" "$version"; then
        emit_log "updating, "
        _asdf_update "$pluginName"
        emit_log "installing version, "
        if _asdf_install "$pluginName" "$version"; then
            :
        else
            end_log_line_err "failed!"
            return 1
        fi
    fi
    emit_log "setting shell, "
    if _asdf_set_shell_version "$pluginName" "$version"; then
        end_log_line "done."
    else
        end_log_line_err "failed!"
        return 1
    fi
}

_is_shim()
{
    local program="$1"
    if exists "$program" && [[ "$(wh "$program")" == $HOME/.asdf/shims/* ]]; then
        return 0
    else
        return 1
    fi
}

_req1_with_asdf()
{
    local program="${1:-}"
    local versionPolicy="${2:-}"
    local package="${3:-}"
    if [ "$versionPolicy" = "$_VERSION_NO_CHECK" ] || [ "$versionPolicy" = "$_VERSION_ANY" ]; then
        emit_log "Checking $(ab "$program") ... "
        if _is_shim "$program"; then
            emit_log "it's a shim, using $(_asdf), "
            # Program not found, using asdf to install it (using latest version, since no version was specified)
            _req1_with_asdf_inner "$program"
        elif exists "$program"; then
            if [ "$versionPolicy" = "$_VERSION_NO_CHECK" ]; then
                version="n/a"
            elif ! version=$(_get_version "$program"); then
                emit_log "not found, using $(_asdf), "
                # Program not found, using asdf to install it (using latest version, since no version was specified)
                if _req1_with_asdf_inner "$program" "" "$package"; then
                    return 0
                else
                    return 1
                fi
            fi
            end_log_line "found at $(_describe_program_and_version "$program" "$version")."
        else
            emit_log "not found, using $(_asdf), "
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

_req1()
{
    local program="$1"
    local versionPolicy="$2"
    local package="$3"
    local tempOutput

    tempOutput="$(mktemp)"
    if [ -z "$tempOutput" ]; then
        err "Can't create temporary file to store output of req_check!"
        echo "$_reqAbortMarker" >&3
    else
        close_and_track_asdf_versions()
        {
            log "$(cat "$tempOutput")"
            rm "$tempOutput"
            env | grep -E "ASDF_.+_VERSION" >&3
        }
        trap close_and_track_asdf_versions EXIT
        {
            {
                if has_asdf; then
                    _req1_with_asdf "$program" "$versionPolicy" "$package"
                else
                    _req1_without_asdf "$program" "$versionPolicy"
                fi
            } || {
                echo "$_reqAbortMarker" >&3
            }
        } >"$tempOutput" 2>&1
    fi
}

_log_if_verbose()
{
    local message=("$@")
    if [ -n "${_REQ_VERBOSE:-}" ]; then
        log "${message[@]}"
    fi
}

_compatible_version_policies()
{
    local firstPolicy="$1"
    local secondPolicy="$2"
    _strictier_policy "$firstPolicy" "$secondPolicy" || _strictier_policy "$secondPolicy" "$firstPolicy"
}

_strictier_policy()
{
    local firstPolicy="$1"
    local secondPolicy="$2"
    if _is_catch_all "$secondPolicy"; then
        return 0
    else
        begins_with "$firstPolicy" "$secondPolicy"
    fi
}

_is_catch_all()
{
    local policy="$1"
    if [ "$policy" = "$_VERSION_ANY" ] || [ "$policy" = "$_VERSION_ANY_VIA_ASDF_IF_AVAILABLE" ] || [ "$policy" = "$_VERSION_NO_CHECK" ]; then
        return 0
    else
        return 1
    fi
}

_is_catch_all_package()
{
    local package="$1"
    test -z "$package"
}

_strictier_package()
{
    local firstPackage="$1"
    local secondPackage="$2"
    _is_catch_all_package "$secondPackage" || [ "$firstPackage" = "$secondPackage" ]
}

_compatible_packages()
{
    local firstPackage="$1"
    local secondPackage="$2"
    if _strictier_package "$firstPackage" "$secondPackage" || _strictier_package "$secondPackage" "$firstPackage"; then
        return 0
    else
        return 1
    fi
}

_req()
{
    if [[ "${REQ_CHECKED:-}" = 1 ]]; then
        exit_err "pre-boot script sanity checks already done, please define all requirements (i.e. all $(b req), $(b req_no_ver), and $(b req_ver) calls) before calling $(b req_check)"
    fi
    programName="$1"
    versionPolicy="$2"
    package="${3:-}"
    if [[ "${_REQ_INCLUDED:-}" = *" $programName:"* ]]; then
        local includedPart=${_REQ_INCLUDED#*" $programName:"}
        local includedValue=${includedPart%%" "*}
        if [[ $includedValue != "$versionPolicy:$package" ]]; then
            local existingVersionPolicy=${includedValue%%:*}
            local existingPackage=${includedValue##*:}
            if _compatible_packages "$existingPackage" "$package" && _compatible_version_policies "$existingVersionPolicy" "$versionPolicy"; then
                if _strictier_policy "$existingVersionPolicy" "$versionPolicy" && _strictier_package "$existingPackage" "$package"; then
                    # No change
                    _log_if_verbose "Found req for program $(ab "$programName"), versionPolicy=$(ab "$versionPolicy") (broader than current $(ab "$existingVersionPolicy")), package=$(ab "$package") (no change)"
                else
                    _REQ_INCLUDED="${_REQ_INCLUDED//$programName:$existingVersionPolicy:$existingPackage/}"
                    _REQ_INCLUDED="$_REQ_INCLUDED $programName:$versionPolicy:$package"
                    _log_if_verbose "Found req for program $(ab "$programName"), versionPolicy=$(ab "$versionPolicy") (narrower than current $(ab "$existingVersionPolicy")), package=$(ab "$package") (narrowed version policy as requested)"
                fi
            else
                exit_err "Found existing, but conflicting, requirement for program $(ab "$programName"), versionPolicy=$(ab "$existingVersionPolicy") (wanted: $(ab "$versionPolicy")), package=$(ab "$existingPackage") (wanted: $(ab "$package")). Cannot continue, please fix your requirements."
            fi
        else
            _log_if_verbose "Found req for program $(ab "$programName"), versionPolicy=$(ab "$versionPolicy"), package=$(ab "$package") (already present)"
        fi
    else
        _REQ_INCLUDED="${_REQ_INCLUDED:-} $programName:$versionPolicy:$package"
        _log_if_verbose "Found req for program $(ab "$programName"), versionPolicy=$(ab "$versionPolicy"), package=$(ab "$package")"
    fi
}

req()
{
    # Behaviour:
    # - without asdf: if program is already installed, use it and print version if available, otherwise fail
    # - with asdf: if program is already installed, use it, otherwise try to install its latest version using asdf
    for p in "$@"; do
        if [ -n "${p}" ]; then
            _req "${p}" "$_VERSION_ANY"
        else
            exit_err "Req arguments: $(ab "$@")\nCannot require program with empty name, perhaps you wanted to us $(b req_ver) ?"
        fi
    done
}

req_no_ver()
{
    # Behaviour:
    # - without asdf: if program is already installed, use it (without calling it to get the version), otherwise fail
    # - with asdf: if program is already installed, use it (without calling it to get the version), otherwise try to install its latest version using asdf
    for p in "$@"; do
        if [ -n "${p}" ]; then
            _req "${p}" "$_VERSION_NO_CHECK"
        else
            exit_err "Req arguments: $(ab "$@")\nCannot require program with empty name, perhaps you wanted to us $(b req_ver) ?"
        fi
    done
}

req_ver()
{
    # Behaviour:
    # - without asdf: same as req (but with a warning) if program is already installed, otherwise fail
    # - with asdf: try to install its latest matching version using asdf, otherwise fail
    local program="$1"
    local versionSpec="${2:-$_VERSION_ANY_VIA_ASDF_IF_AVAILABLE}"
    local package="${3:-}"
    _req "$program" "$versionSpec" "$package"
}

req_ver_opt()
{
    # Behaviour:
    # - without asdf: same as req (but with a warning) if program is already installed, otherwise just ignore
    # - with asdf: try to install its latest matching version using asdf, otherwise just ignore
    local program="$1"
    local versionSpec="${2:-$_VERSION_ANY_VIA_ASDF_IF_AVAILABLE}"
    local package="${3:-}"
    _req "-$program" "$versionSpec" "$package"
}

_describe_asdf_status()
{
    if has_asdf; then
        echo "$(_asdf) useable (use $(ab "_ASDF_DISABLED=y") to disable)"
    else
        if could_use_asdf; then
            echo -n "$(_asdf) detected but $(b disabled) via $(ab "_ASDF_DISABLED=$_ASDF_DISABLED")"
        else
            echo -n "$(_asdf) not detected"
        fi
        echo ", using existence check only"
    fi
}

req_check()
{
    REQ_CHECKED=1

    log "Performing pre-boot script sanity checks [$(_describe_asdf_status)] ..."
    local programNameMarker="XXXXXXX"
    local _temp_cached_asdf_plugin_list_file=""
    if has_asdf; then
        _temp_cached_asdf_plugin_list_file="$(mktemp -t "_asdf_plugin_list_cache_${programNameMarker}")"
        touch "$_temp_cached_asdf_plugin_list_file"
        {
            local _temp_cached_asdf_plugin_list_file_during_build
            _temp_cached_asdf_plugin_list_file_during_build="$(mktemp -t "_asdf_plugin_list_cache_${programNameMarker}_incomplete")"
            _asdf_all_installed_plugins >"$_temp_cached_asdf_plugin_list_file_during_build"
            mv "$_temp_cached_asdf_plugin_list_file_during_build" "$_temp_cached_asdf_plugin_list_file"
        } &
    fi
    tempVersions=()
    for entry in $_REQ_INCLUDED; do
        local program=${entry%%:*}
        local secondPart=${entry#*:}
        local versionPolicy=${secondPart%%:*}
        local package=${secondPart##*:}
        local cleanedProgramName="${program#-}"
        local tempVersion
        tempVersion="$(mktemp -t "${program}${programNameMarker}")"
        _cached_asdf_plugin_list_file="${_temp_cached_asdf_plugin_list_file:-}" _req1 "$cleanedProgramName" "$versionPolicy" "$package" 3>"$tempVersion" &
        tempVersions+=("$tempVersion")
    done
    cleanup_temporary_version_files()
    {
        for tempVersion in "${tempVersions[@]}"; do
            [ -f "$tempVersion" ] && \rm "$tempVersion"
        done
        [ -n "${_temp_cached_asdf_plugin_list_file:-}" ] && [ -f "$_temp_cached_asdf_plugin_list_file" ] && \rm "$_temp_cached_asdf_plugin_list_file"
    }
    trap cleanup_temporary_version_files RETURN
    wait
    local failedRequirements=()
    local failedOptionalRequirements=()
    for tempVersion in "${tempVersions[@]}"; do
        local simpleFileName="${tempVersion##*/}"
        local program="${simpleFileName%%"${programNameMarker}"*}"
        while IFS= read -r line; do
            if [ "$line" == "$_reqAbortMarker" ]; then
                if [[ "$program" = -* ]]; then
                    failedOptionalRequirements+=("\"${program#-}\"")
                else
                    failedRequirements+=("\"$program\"")
                fi
            else
                local var
                var="$(echo "$line" | cut -d"=" -f1)"
                local value
                value="$(echo "$line" | cut -d"=" -f2-)"
                export "$var"="$value"
            fi
        done <"$tempVersion"
        rm "$tempVersion"
    done
    if ((${#failedRequirements[@]} > 0)); then
        whine "Cowardly refusing to execute this script without the required programs ${failedRequirements[*]}. Have a nice day!"
    elif ((${#failedOptionalRequirements[@]} > 0)); then
        log "$(yellow "Despite optional requirements ${failedOptionalRequirements[*]} are missing, this script $(ab "$(tildify "$0")")")" "$(yellow "can still start.")"
    else
        log "$(green "Script sanity checks completed successfully, current script $(ab "$(tildify "$0")") can start.")"
    fi
}
