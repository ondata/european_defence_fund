#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/tmp

# First generate the list of Italian participants
mlr --icsv --ojsonl filter '$postalAddress_countryCode_abbreviation=="IT"' then cut -f pic,webLink then uniq -a then filter -x 'is_null($webLink)' "${folder}"/../data/progetti_finanziati/output/flattened/csv/metadata_participants.csv > "${folder}"/tmp/italian_participants.jsonl

# Create output file for VAT numbers
echo "[]" > "${folder}"/tmp/vat_numbers.json

# Process each participant
while IFS= read -r line; do
    pic=$(echo "$line" | jq -r '.pic')
    url=$(echo "$line" | jq -r '.webLink')
    
    # Ensure URL starts with http:// or https://
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="http://$url"
    fi
    
    echo "Processing $url..."
    
    # Try to fetch the website content and extract VAT numbers
    if vat_numbers=$(curl -L --max-time 10 --silent "$url" | grep -oE '[0-9]{11}' | sort -u | paste -sd,); then
        if [ ! -z "$vat_numbers" ]; then
            # Add new entry to JSON array
            tmp_file="${folder}/tmp/vat_numbers_tmp.json"
            jq --arg pic "$pic" --arg vat "$vat_numbers" \
               '. += [{"pic": $pic, "vat_numbers": $vat}]' \
               "${folder}/tmp/vat_numbers.json" > "$tmp_file" && mv "$tmp_file" "${folder}/tmp/vat_numbers.json"
            echo "Found VAT numbers for PIC $pic: $vat_numbers"
        fi
    fi
    
    # Add small delay to be nice to servers
    sleep 2
    
done < "${folder}"/tmp/italian_participants.jsonl
