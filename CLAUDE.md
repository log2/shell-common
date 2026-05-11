# shell-common — development guide

## Purpose

Core bash utility library. Provides logging, styling, requirement checking, string/file/calc helpers, and asdf version management. All other `play/` repos depend on this.

## Structure

```
lib/          # Source-only library modules (loaded via dep or include)
  log.sh      # log, warn, whine, start_log_line, end_log_line, end_log_line_with_color
  styles.sh   # b, i, ab, red, green, yellow, a — terminal colour/style helpers
  req.sh      # req_ver, req_no_ver, req_check — tool version enforcement
  asdf.sh     # has_asdf, ensure_asdf, ensure_asdf_plugin_version_shell
  strings.sh  # trim, lower, upper, contains
  files.sh    # volume_free_space, volume_used_space, volume_size
  exist.sh    # exists — wraps `command -v`
  calc.sh     # compute — bc wrapper
  check.sh    # check helpers
samples/      # Usage examples
tests/        # bats test suite
  vendor/     # shellmock (vendored, do not edit)
stub/         # basher stub for local dev without basher installed
```

## Loading convention

Library files are sourced, never executed directly. Two loading mechanisms coexist:

```bash
# With dep/basher (runtime):
dep include log2/shell-common log

# Without dep (bootstrapped directly via include):
include log2/shell-common lib/log.sh
```

Always guard with:
```bash
if type dep &>/dev/null; then
    dep include log2/shell-common <module>
else
    include log2/shell-common lib/<module>.sh
fi
```

## Adding a function

1. Add to the appropriate `lib/*.sh` module (or create a new one)
2. If creating a new module, add it to `package.sh`
3. Run `pre-commit run --all-files` — shfmt reformats, shellcheck validates
4. Add a bats test in `tests/`

## Testing

```bash
# Run all tests (requires bats)
bats tests/
```

Tests use shellmock (vendored in `tests/vendor/`) for command mocking. The `capture` array is populated by `shellmock_verify` — shellcheck disable SC2154 is expected there.

## Versioning

Version is declared in `package.sh`. Increment it before tagging a release. Consumers pin by git tag via `dep include log2/shell-common:<tag>`.

## Pre-commit

All hooks are enforced on commit:
- `shfmt -i 4 -bn -ci -fn` — canonical formatting
- `shellcheck --severity=warning` — excludes `tests/vendor/` and `stub/`
- Standard file hygiene (trailing whitespace, EOF, merge conflicts)
