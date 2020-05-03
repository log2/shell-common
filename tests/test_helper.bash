load vendor/bats-support/load
load vendor/bats-assert/load
load vendor/bats-file/load

export COMMON_TEST_DIR="${BATS_TMPDIR}/common"
export COMMON_ORIGIN_DIR="${COMMON_TEST_DIR}/origin"
export COMMON_CWD="${COMMON_TEST_DIR}/cwd"
export COMMON_TMP_BIN="${COMMON_TEST_DIR}/bin"

export COMMON_ROOT="${BATS_TEST_DIRNAME}/.."
export COMMON_PREFIX="${COMMON_TEST_DIR}/prefix"
export COMMON_INSTALL_BIN="${COMMON_PREFIX}/bin"
export COMMON_INSTALL_MAN="${COMMON_PREFIX}/man"
export COMMON_PACKAGES_PATH="$COMMON_PREFIX/packages"

export FIXTURES_DIR="${BATS_TEST_DIRNAME}/fixtures"

export PATH="${BATS_TEST_DIRNAME}/libexec:$PATH"
export PATH="${BATS_TEST_DIRNAME}/../libexec:$PATH"
export PATH="${COMMON_TMP_BIN}:$PATH"

mkdir -p "${COMMON_TMP_BIN}"
mkdir -p "${COMMON_TEST_DIR}/path"

mkdir -p "${COMMON_ORIGIN_DIR}"

mkdir -p "${COMMON_CWD}"

setup() {
  cd "${COMMON_CWD}" || exit
}

teardown() {
  rm -rf "$COMMON_TEST_DIR"
}

lib() {
    local libname="$1"
    echo "${COMMON_ROOT}/lib/$libname.sh"
}

include() {
    local libname="$1"
    # shellcheck disable=SC1090
    source "$(lib "$libname")"
}

# load lib/mocks
# load lib/package_helpers
# load lib/commands