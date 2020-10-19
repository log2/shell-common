#!/usr/bin/env bash

if type dep &>/dev/null ; then
    dep include log2/shell-common log
else
    include log2/shell-common lib/log.sh
fi

req shellcheck

check_shell_scripts() {
    baseDir=${1:-"."}
    reportFileName=${2:-"checkstyle-report.xml"}

    log "Starting check in directory $(b "$baseDir"), working directory is $(b "$(pwd)")"

    strict="--enable=add-default-case,avoid-nullary-conditions"

    while IFS= read -r -d '' shellscript
    do
        log
        log "Checking $(b "$shellscript") for errors ..."
        analyze() {
            shellcheck --source-path="$baseDir" --check-sourced --external-sources --severity="$1" "${@:2}" "$shellscript" 
        }
        if analyze error ; then
            log "No errors in $(b "$shellscript"), continuing with analysis"
        else
            whine "Found errors in $(b "$shellscript"), can't continue"
        fi
        log "Checking $(b "$shellscript") for issues ..."
        if analyze style $strict ; then
            log "No issues whatsoever found in $(b "$shellscript")"
        else
            log "Found some non-fatal issues in $(b "$shellscript")"
        fi
    done < <(find "$baseDir" -name "*.sh" -print0)

    reportFile="target/$reportFileName"
    mkdir -p "$(dirname "$reportFile")"
    log "Producing result in CheckStyle format in file $(b "$reportFile")"

    shellcheck \
        --source-path="$baseDir" \
        --check-sourced \
        --external-sources \
        --severity=style \
        --format=checkstyle \
        "$(find . -name "*.sh")" > "$reportFile"

    log "Check completed, checkstyle-compatible report has been produced in $(b "$reportFile")"
}