#!/usr/bin/env bats

load test_helper

include calc

@test "fp division works" {
    run compute 2 / 3
    assert_success
    assert_output "0.666667"
}

@test "fp division and multiplication works" {
    run compute 2 / 3
    assert_success
    run compute $output * 3
    assert_output "2"
}

@test "int modulus works" {
    run compute 7 % 3
    assert_success
    assert_output "1"
}

@test "int conversion works" {
    run compute 42 / 5
    assert_success
    assert_output "8.4"

    run compute "int(42 / 5)"
    assert_success
    assert_output "8"
}

@test "conversion to int number works" {
    run to_num ' 4 '
    assert_success
    assert_output "4"
}

@test "conversion to fp number works" {
    run to_num ' 4.33 '
    assert_success
    assert_output "4.33"
}