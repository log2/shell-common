mock_command()
{
    local command="$1"
    mkdir -p "${COMMON_TEST_DIR}/path/$command"
    cat >"${COMMON_TEST_DIR}/path/$command/$command" <<SH
#!/usr/bin/env bash
echo "$command \$@"
SH
    chmod +x "${COMMON_TEST_DIR}/path/$command/$command"
    export PATH="${COMMON_TEST_DIR}/path/$command:$PATH"
}

mock_clone()
{
    export PATH="${BATS_TEST_DIRNAME}/fixtures/commands/basher-_clone:$PATH"
}
