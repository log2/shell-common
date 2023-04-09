#!/usr/bin/env bash

set -euo pipefail

eval "$(direnv stdlib)"

export _DEP_VERBOSENESS_LEVEL=0

# shellcheck disable=SC1090
. "$(fetchurl "https://raw.githubusercontent.com/EcoMind/dep-bootstrap/0.5.5/dep-bootstrap.sh" "sha256-rtqYzq7o1d+rymFH00Cq/tve28vbOKSKxoDFvO0zjd4=")" 0.5.5

dep define "log2/shell-common:local-SNAPSHOT"

dep include log2/shell-common req

# working without asdf
#req shellcheck
#req docker
#req git
req_ver_opt kubectl 1.99.1
req_ver yq 4.20

req_ver_opt zzz 99.1 non-existent-plugin

# _req1_with_asdf kubectl "1.99.1"

# _asdf_find_latest kubectl 1.99

req_check

# echo $ASDF_FLUX2_VERSION
# export ASDF_FLUX2_VERSION
