#!/usr/bin/env bats

load test_helper

include log2/shell-common lib/req.sh

export _REQ_VERBOSE=1
export _DISABLE_STYLING=1
export _SILENT_STYLING_SETUP=1

@test "req works" {
    run req grep
    assert_success
}

@test "req_no_ver works" {
    run req_no_ver wc
    assert_success
}

@test "req_ver works" {
    run req_ver grep
    assert_success
}

@test "req_ver with version works" {
    run req_ver grep 2.5
    assert_success
}

@test "req_ver with version and package works" {
    run req_ver aws 2. awscli
    assert_success
}

@test "conflicting req_ver is rejected" {
    req_ver aws 2. awscli
    run req_ver aws 3. awscli
    assert_failure
}

@test "non-conflicting (via restriction) req_ver is accepted " {
    req_ver aws "" awscli
    run req_ver aws 2. awscli
    assert_success
}

@test "non-conflicting (via expansion) req_ver is accepted " {
    req_ver aws 2. awscli
    run req_ver aws "" awscli
    assert_success
}

@test "non-conflicting (via expansion) req_ver + req is accepted " {
    req_ver aws 2. awscli
    run req aws
    assert_success
}

@test "non-conflicting (via expansion) req_ver + req_no_ver is accepted " {
    req_ver aws 2. awscli
    run req_no_ver aws
    assert_success
}

@test "tricky non-conflicting (via restriction) req_ver is accepted " {
    req_ver aws 2. awscli
    run req_ver aws 2.1 awscli
    assert_success
}

@test "tricky non-conflicting (via expansion) req_ver is accepted " {
    req_ver aws 2.1 awscli
    run req_ver aws 2. awscli
    assert_success
}
