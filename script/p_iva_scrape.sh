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

    # Clean and normalize URL
    url=$(echo "$url" | tr -d '[:space:]')

    # Try different URL variants
    urls=()
    if [[ "$url" =~ ^https?:// ]]; then
        urls+=("$url")
    else
        if [[ "$url" =~ ^www\. ]]; then
            urls+=("http://$url" "https://$url")
        else
            urls+=("http://www.$url" "https://www.$url" "http://$url" "https://$url")
        fi
    fi

    success=0
    for try_url in "${urls[@]}"; do
        echo "Trying $try_url..."

        if page_content=$(curl -L --max-time 15 --silent --fail "$try_url" 2>/dev/null); then
            # Look for VAT numbers in various formats, including those with IT prefix
            if vat_numbers=$(echo "$page_content" | grep -oE '(VAT|IVA|PI|P.IVA|Partita IVA)[^0-9]*(IT)?[0-9]{11}' | grep -oE '(IT)?[0-9]{11}' | sed 's/^IT//' | sort -u | paste -sd,); then
                if [ ! -z "$vat_numbers" ]; then
                    # Add new entry to JSON array
                    tmp_file="${folder}/tmp/vat_numbers_tmp.json"
                    jq --arg pic "$pic" --arg vat "$vat_numbers" --arg url "$try_url" \
                       '. += [{"pic": $pic, "vat_numbers": $vat, "source_url": $url}]' \
                       "${folder}/tmp/vat_numbers.json" > "$tmp_file" && mv "$tmp_file" "${folder}/tmp/vat_numbers.json"
                    echo "Found VAT numbers for PIC $pic: $vat_numbers"
                    success=1
                    break
                fi
            fi
        fi
    done

    if [ $success -eq 0 ]; then
        echo "No VAT numbers found for PIC $pic"
        # Add entry with empty VAT numbers but include the attempted URL
        tmp_file="${folder}/tmp/vat_numbers_tmp.json"
        jq --arg pic "$pic" --arg url "$url" \
           '. += [{"pic": $pic, "vat_numbers": "", "source_url": $url}]' \
           "${folder}/tmp/vat_numbers.json" > "$tmp_file" && mv "$tmp_file" "${folder}/tmp/vat_numbers.json"
    fi

    # Add small delay to be nice to servers
    sleep 0

done < "${folder}"/tmp/italian_participants.jsonl

cp "${folder}"/tmp/vat_numbers.json "${folder}"/../data/progetti_finanziati/output/vat_numbers.json
