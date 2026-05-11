# shell-common — status

## Health: good

- All functions documented in code
- bats tests cover calc, files, strings, req
- shellcheck clean (severity=warning)
- shfmt enforced

## Known gaps

- `check.sh` has no dedicated tests
- `exist.sh` and `styles.sh` have no tests
- `asdf.sh` is complex and untested (side-effectful; mocking asdf is non-trivial)
- `req.sh` SC2317 warnings suppressed: code after `exit` in subshell trap is unreachable per shellcheck but intentional

## Tech debt

- `_bootstrap.sh` in stub/ assumes basher layout; kept for compatibility but rarely needed
- `tests/vendor/shellmock` is pinned at an old version with many SC warnings — vendored, do not touch
- Some functions in `req.sh` are complex enough to warrant splitting

## Dependencies

None — this is the base layer. Other `play/` repos depend on this.
