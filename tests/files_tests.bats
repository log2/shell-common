#!/usr/bin/env bats

load test_helper

load vendor/shellmock/shellmock

include files

setup()
{
    shellmock_clean
}

teardown()
{
    if [ -z "$TEST_FUNCTION" ]; then
        shellmock_clean
    fi
}

prepare_df() {
    local dir="$1"
    shellmock_expect df --match "-h $dir" --output "$(cat <<EOF
Filesystem     Size   Used  Avail Capacity iused      ifree %iused  Mounted on
/dev/sda1      466Gi  10Gi   48Gi    18%  487619 4881965261    0%   $dir
EOF
)"
}

@test "free space works" {
    local dir="/tmp"
    prepare_df "$dir"
    run volume_free_space "$dir"
    assert_success
    assert_output "48Gi"
    shellmock_verify
    [ "${capture[0]}" = "df-stub -h $dir" ]
}

@test "used space works" {
    local dir="/tmp"
    prepare_df "$dir"
    run volume_used_space "$dir"
    assert_success
    assert_output "10Gi"
    shellmock_verify
    [ "${capture[0]}" = "df-stub -h $dir" ]
}

@test "total space works" {
    local dir="/tmp"
    prepare_df "$dir"
    run volume_size "$dir"
    assert_success
    assert_output "466Gi"
    shellmock_verify
    [ "${capture[0]}" = "df-stub -h $dir" ]
}

# @test "dir size works" {
#     local dir="/tmp"
#     shellmock_expect du --match "-d 0 -h $dir" --output "$(cat <<EOF
#  16Gi   $dir

# EOF
# )"
#     run size "$dir"
#     assert_success
#     assert_output "16Gi"
#     shellmock_verify
#     [ "${capture[0]}" = "du-stub -d 0 -h $dir" ]
# }


