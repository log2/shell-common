#!/usr/bin/env bats

load test_helper

TAB=$(printf "%b" "\t")

include strings

@test "strip_prefix works with spaces" {
    run strip_prefix "a b/" "a b/c"
    assert_success
    assert_output "c"
}

@test "strip_prefix works without spaces" {
    run strip_prefix "a_b/" "a_b/c"
    assert_success
    assert_output "c"
}

@test "strip_prefix works with spaces and non-match" {
    run strip_prefix "a b/" "a x/c"
    assert_success
    assert_output "a x/c"
}

@test "strip_prefix works without spaces and non-match" {
    run strip_prefix "a_b/" "a_x/c"
    assert_success
    assert_output "a_x/c"
}

@test "begins_with works without spaces" {
    run begins_with "a_b/" "a_b/c"
    assert_success
}

@test "begins_with works with spaces" {
    run begins_with "a b/" "a b/c"
    assert_success
}

@test "begins_with works without spaces and non-match" {
    run begins_with "a_b/" "a_x/c"
    assert_failure
}

@test "begins_with works with spaces and non-match" {
    run begins_with "a b/" "a x/c"
    assert_failure
}

@test "trim works with spaces" {
    run trim " a b "
    assert_success
    assert_output "a b"
}

@test "trim works with tabs" {
    run trim "${TAB}a b${TAB}"
    assert_success
    assert_output "a b"
}

@test "trim works with tabs and spaces" {
    run trim " ${TAB} ${TAB}a b${TAB} ${TAB} "
    assert_success
    assert_output "a b"
}
