#!/usr/bin/env bats

load test_helper

include log2/shell-common lib/asdf.sh

export _DISABLE_STYLING=1
export _SILENT_STYLING_SETUP=1

# Stub asdf: behaviour is driven by STUB_ASDF_LIST, STUB_ASDF_LATEST and STUB_ASDF_LATEST_RC
asdf()
{
    case "$1" in
        list)
            if [ "${2:-}" = all ]; then
                printf '%s\n' "${STUB_ASDF_LIST_ALL:-}"
            else
                printf '%s\n' "${STUB_ASDF_LIST:-}"
            fi
            ;;
        latest)
            printf '%s\n' "${STUB_ASDF_LATEST:-}"
            return "${STUB_ASDF_LATEST_RC:-0}"
            ;;
    esac
}

@test "version cleanup strips the current marker" {
    run _asdf_version_cleanup " *1.37.2"
    assert_success
    assert_output "1.37.2"
}

@test "version cleanup of a plain version is unchanged" {
    run _asdf_version_cleanup "1.35.0"
    assert_success
    assert_output "1.35.0"
}

@test "version cleanup picks the highest of many versions" {
    run _asdf_version_cleanup "$(printf '  1.35.0\n  1.35.10\n')"
    assert_success
    assert_output "1.35.10"
}

@test "find_latest with a single local match returns it" {
    STUB_ASDF_LIST="  1.35.0"
    run _asdf_find_latest kubectl 1.35
    assert_success
    assert_output "1.35.0"
}

@test "find_latest with multiple local matches returns the highest, single token" {
    STUB_ASDF_LIST="$(printf '  1.35.0\n  1.35.10\n')"
    run _asdf_find_latest kubectl 1.35
    assert_success
    assert_output "1.35.10"
}

@test "find_latest with multiple local matches and a current marker" {
    STUB_ASDF_LIST="$(printf '  1.37.1\n *1.37.2\n  1.37.10\n')"
    run _asdf_find_latest kubectl 1.37
    assert_success
    assert_output "1.37.10"
}

@test "find_latest uses asdf latest when nothing is installed locally" {
    STUB_ASDF_LIST=""
    STUB_ASDF_LATEST="1.35.10"
    run _asdf_find_latest kubectl 1.35
    assert_success
    assert_output "1.35.10"
}

@test "find_latest falls back to list all, filtering prefix and prereleases" {
    STUB_ASDF_LIST=""
    STUB_ASDF_LATEST_RC=1
    STUB_ASDF_LIST_ALL="$(printf '1.34.9\n1.35.0\n1.35.10\n1.35.11-rc1\n1.36.0\n')"
    run _asdf_find_latest kubectl 1.35
    assert_success
    assert_output "1.35.10"
}
