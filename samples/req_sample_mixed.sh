#!/usr/bin/env bash

set -euo pipefail

eval "$(direnv stdlib)"

export _DEP_VERBOSENESS_LEVEL=0

# shellcheck disable=SC1090
. "$(fetchurl "https://raw.githubusercontent.com/EcoMind/dep-bootstrap/0.5.5/dep-bootstrap.sh" "sha256-rtqYzq7o1d+rymFH00Cq/tve28vbOKSKxoDFvO0zjd4=")" 0.5.5

dep define "log2/shell-common:local-SNAPSHOT"

dep include log2/shell-common req

#_REQ_VERBOSE=1

# working without asdf
req shellcheck
req gcloud
req_no_ver wc
req xmlstarlet
req docker
req git
req_no_ver realpath
req grep
req_no_ver sed
req_no_ver tr
req awk
req_no_ver xargs
req_no_ver cut

# working better with asdf
req eksctl
req_no_ver kubectl
req_ver az 2.45.0 azure-cli
req_ver jq "1.6"
req helm

# working without asdf in fallback mode, better with asdf
req_ver mvn "" maven
req_ver aws "" awscli
req_ver az
req_ver yq 4.20.1
# req_ver az "2." azure-cli

req_no_ver minica
req k3d

req_ver flux "" flux2

# req swamp

req_check

# echo $ASDF_FLUX2_VERSION
# export ASDF_FLUX2_VERSION
