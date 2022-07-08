#!/usr/bin/env bash

eval "$(direnv stdlib)"

export _DEP_VERBOSENESS_LEVEL=0

# shellcheck disable=SC1090
. "$(fetchurl "https://raw.githubusercontent.com/EcoMind/dep-bootstrap/0.5.1/dep-bootstrap.sh" "sha256-lOYbrk89hNgXowWn1q17tpqUeNnEXJLyDTl7mLhbcpU=")" 0.5.1

dep define "log2/shell-common:local-SNAPSHOT"

dep include log2/shell-common req

# working without asdf
req shellcheck
req_ver gcloud 392.0.0
req_no_ver wc
req xmlstarlet
req docker
req git
req realpath
req grep
req_no_ver sed
req_no_ver tr
req awk
req_no_ver xargs
req_no_ver cut

# working better with asdf
req_ver eksctl 0.105.0
req_ver kubectl 1.24.2
req_ver az
req_ver jq "1.6"
req_ver helm 3.9.0

# working without asdf in fallback mode, better with asdf
req_ver mvn 3.8.6 maven
req_ver aws 2.7.13 awscli
req_ver az
req_ver yq 4.20.1
# req_ver az "2." azure-cli

req_no_ver minica
req_ver k3d 5.4.3

req_ver flux 0.31.3 flux2

# req swamp

req_check

# echo $ASDF_FLUX2_VERSION
# export ASDF_FLUX2_VERSION
