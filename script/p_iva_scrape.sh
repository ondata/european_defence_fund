#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/tmp

mlr --icsv --ojsonl filter '$postalAddress_countryCode_abbreviation=="IT"' then cut -f pic,webLink then uniq -a then filter -x 'is_null($webLink)' "${folder}"/../data/progetti_finanziati/output/flattened/csv/metadata_participants.csv > "${folder}"/tmp/italian_participants.jsonl
