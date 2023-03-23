#!/usr/bin/env bash

if type dep &>/dev/null; then
    dep include log2/shell-common exist
else
    include log2/shell-common lib/exist.sh
fi

_ASDF_CHECKED=no

_initialize_asdf()
{
    # Ensure that asdf integration is installed (otherwise, we couldn't export asdf-set plugin versions)
    source_if_exists "${ASDF_DIR:-$HOME/.asdf}/asdf.sh"
    if exists brew; then
        source_if_exists "$(brew --prefix asdf)/libexec/asdf.sh"
    fi
}

could_use_asdf()
{
    exists asdf && exists grep && exists xargs && exists tr && exists tail && exists sort
}

has_asdf()
{
    if [ "$_ASDF_CHECKED" == "no" ]; then
        if [ -z "${_ASDF_DISABLED:-}" ] && could_use_asdf; then
            _ASDF_CHECKED=found
            _initialize_asdf
            return 0
        else
            _ASDF_CHECKED=notfound
            return 1
        fi
    elif [ "$_ASDF_CHECKED" == "found" ]; then
        return 0
    else
        return 1
    fi
}

ensure_asdf()
{
    if ! has_asdf; then
        whine "$(b asdf) not available, please install it via $(ab "brew install asdf")"
    fi
}

get_all_asdf_available_plugins()
{
    ensure_asdf
    if [ -z "${_ALL_ASDF_PLUGINS_AVAILABLE:-}" ]; then
        # Cache list of all asdf plugins available
        _ALL_ASDF_PLUGINS_AVAILABLE="$(asdf plugin list all)"
    fi
    echo "$_ALL_ASDF_PLUGINS_AVAILABLE"
}

_cached_asdf_plugin_list_file=

_asdf_all_installed_plugins()
{
    ensure_asdf
    if [ -z "${_cached_asdf_plugin_list:-}" ]; then
        if [ -n "${_cached_asdf_plugin_list_file:-}" ]; then
            while [ ! -s "${_cached_asdf_plugin_list_file}" ]; do
                sleep 0.1
            done
            _cached_asdf_plugin_list="$(cat "${_cached_asdf_plugin_list_file}")"
        else
            _cached_asdf_plugin_list="$(asdf plugin list)"
        fi
    fi
    echo "$_cached_asdf_plugin_list"
}

_asdf_has_plugin()
{
    local pluginName="$1"
    _asdf_all_installed_plugins | grep -q "^$pluginName\$"
}

_asdf_add_plugin()
{
    local pluginName="$1"
    if asdf plugin add "$pluginName"; then
        unset _cached_asdf_plugin_list_file
        unset _cached_asdf_plugin_list
    fi
}

ensure_asdf_plugin()
{
    local pluginName="$1"
    if ensure_asdf; then
        if ! _asdf_has_plugin "$pluginName"; then
            _asdf_add_plugin "$pluginName"
        fi
    else
        whine "Can't install plugin $(ab "$pluginName") in asdf, $(ab asdf) is not available"
    fi
}

_asdf_version_is_installed()
{
    local pluginName="$1"
    local version="$2"
    asdf list "$pluginName" 2>/dev/null | grep -qE "^\s*\*?${version}$"
}

_asdf_update()
{
    local pluginName="$1"
    asdf plugin update "$pluginName" >/dev/null 2>&1
}

_asdf_install()
{
    local pluginName="$1"
    local version="$2"
    asdf install "$pluginName" "$version" >/dev/null 2>&1
}

ensure_asdf_plugin_version()
{
    local pluginName="$1"
    local version="$2"
    if ensure_asdf_plugin "$pluginName"; then
        log "Ensuring that $(ab "$pluginName") version $(ab "$version") is installed in asdf"
        if _asdf_version_is_installed "$pluginName" "$version"; then
            log "Version $(ab "$version") of $(ab "$pluginName") is already installed"
        else
            _asdf_update "$pluginName"
            if _asdf_install "$pluginName" "$version"; then
                log "$(ab "$pluginName") version $(ab "$version") is installed in asdf"
            else
                whine "Couldn't install $(ab "$pluginName") version $(ab "$version") in asdf"
            fi
        fi
    fi
}

_asdf_set_shell_version()
{
    local pluginName="$1"
    local version="$2"
    asdf shell "$pluginName" "$version"
}

ensure_asdf_plugin_version_shell()
{
    local pluginName="$1"
    local version="$2"
    if ensure_asdf_plugin_version "$pluginName" "$version"; then
        log "Setting $(ab "$pluginName") version $(ab "$version") in asdf as shell (env) version"
        if _asdf_set_shell_version "$pluginName" "$version"; then
            log "Successfully set $(ab "$pluginName") version $(ab "$version") in asdf as shell (env) version"
        else
            whine "Couldn't set $(ab "$pluginName") version $(ab "$version") in asdf as shell (env) version"
        fi
    else
        whine "$(ab "$pluginName") version $(ab "$version") is not installed in asdf and couldn't install"
    fi
}

_derive_asdf_plugin_name()
{
    local program="$1"
    local package="$2"
    if [ -n "$package" ]; then
        echo "$package"
    else
        echo "$program"
    fi
}

_asdf_version_cleanup()
{
    local version="$1"
    echo "${version/ *\*/}" | xargs
}

_asdf_find_latest()
{
    local pluginName="$1"
    local pluginVersionPrefix="$2"

    if [ -n "$pluginVersionPrefix" ]; then
        local localMatchingVersion
        if localMatchingVersion="$(asdf list "$pluginName" "$pluginVersionPrefix" 2>/dev/null)"; then
            if [ -n "$localMatchingVersion" ]; then
                _asdf_version_cleanup "$localMatchingVersion"
                # Local check succeded, use locally available version
                return 0
            fi
        fi
    fi
    if ! asdf latest "$pluginName" "$pluginVersionPrefix" 2>/dev/null; then
        # Fallback when GitHub quota is exhausted
        local latestMatchingVersion
        _get_all_versions()
        {
            asdf list-all "$pluginName" 2>/dev/null
            asdf list "$pluginName" 2>/dev/null | xargs | tr ' ' '\n' # merge with already installed versions, to overcome transient misbehaviour in list-all of some plugins (e.g., see https://github.com/sudermanjr/asdf-yq/issues/10)
        }
        _grab_latest()
        {
            grep -vE '(alpha|beta|rc)' | sort -V | tail -1
        }
        if [ -z "${pluginVersionPrefix:-}" ]; then
            latestMatchingVersion="$(_get_all_versions | _grab_latest)"
        else
            latestMatchingVersion="$(_get_all_versions | grep ^"$pluginVersionPrefix" | _grab_latest)"
        fi
        _asdf_version_cleanup "$latestMatchingVersion"
    fi
}
