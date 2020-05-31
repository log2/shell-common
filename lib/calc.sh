#!/usr/bin/env bash

compute() {
    local expression="$*"
    awk "BEGIN { print $expression }"
}

to_num() {
    local number="$*"
    compute "$number"
}