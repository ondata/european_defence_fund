#!/bin/bash

#set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/tmp

# First generate the list of Italian participants
mlr --icsv --ojsonl filter '$postalAddress_countryCode_abbreviation=="IT"' then cut -f pic,webLink then uniq -a then filter -x 'is_null($webLink)' "${folder}"/../data/progetti_finanziati/output/flattened/csv/metadata_participants.csv > "${folder}"/tmp/italian_participants.jsonl

# Initialize or load existing VAT numbers file
vat_file="${folder}"/../data/progetti_finanziati/output/vat_numbers.json
if [ ! -f "$vat_file" ]; then
    echo "[]" > "$vat_file"
fi

# Create temporary working copy with unique entries only
jq 'unique_by(.pic)' "$vat_file" > "${folder}"/tmp/vat_numbers.json

# Process each participant
while IFS= read -r line; do
    pic=$(echo "$line" | jq -r '.pic')

    # Check if PIC already exists with a VAT number in vat_numbers.json
    existing_entry=$(jq --arg pic "$pic" '.[] | select(.pic == $pic and .vat_numbers != "")' "${folder}"/tmp/vat_numbers.json)
    if [ ! -z "$existing_entry" ]; then
        echo "PIC $pic already has VAT number, skipping..."
        continue
    fi

    # Check if PIC exists but without VAT number
    existing_empty=$(jq --arg pic "$pic" '.[] | select(.pic == $pic and .vat_numbers == "")' "${folder}"/tmp/vat_numbers.json)
    if [ ! -z "$existing_empty" ]; then
        echo "PIC $pic exists but has no VAT number, will try again..."
    fi

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

        # Get the effective URL after redirects first with 15 second timeout
        if effective_url=$(curl -kL --max-time 15 -o /dev/null -w '%{url_effective}\n' "$try_url" 2>/dev/null | head -n1); then
            # Clean up the effective URL and check if it's valid
            effective_url=$(echo "$effective_url" | tr -d '\n' | grep -E '^https?://' || echo "")
            if [ ! -z "$effective_url" ]; then
                echo "Effective URL: $effective_url"
            else
                echo "Invalid effective URL format from $try_url"
                effective_url="NA"
                continue
            fi
        else
            echo "Failed to connect to $try_url"
            effective_url="NA"
            continue
        fi

        if page_content=$(curl -skL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36" -H "Accept-Language: en-US,en;q=0.9" --max-time 30 --retry 3 --retry-delay 1 --silent "$effective_url" 2>/dev/null); then
            # Use LLM to extract VAT number
            if llm_result=$(echo "$page_content" | strip-tags | llm -s "Extract only the 'Partita IVA' from a given text, ignoring any 'Codice Fiscale' present. The 'Partita IVA' may sometimes include the 'IT' prefix, like 'IT02854220213'. If a 'Partita IVA' is found, provide it in an object under the field 'partita_iva'. If no 'Partita IVA' is found, return the field empty. The output must be a single JSON object with a single field: {'partita_iva': '[value]'} if found, or {'partita_iva': ''} if not found." -o json_object true); then
                # Parse JSON output, handling potential errors
                if vat_numbers=$(echo "$llm_result" | jq -r 'if type == "object" then .partita_iva else "" end' 2>/dev/null); then
                    if [ ! -z "$vat_numbers" ] && [ "$vat_numbers" != "null" ]; then
                        # Update or add entry
                        tmp_file="${folder}/tmp/vat_numbers_tmp.json"
                        jq --arg pic "$pic" --arg vat "$vat_numbers" --arg url "$try_url" --arg eff_url "$effective_url" '
                            (map(select(.pic != $pic)) + [{
                                "pic": $pic,
                                "vat_numbers": $vat,
                                "source_url": $url,
                                "effective_url": $eff_url
                            }]) | sort_by(.pic)
                        ' "${folder}/tmp/vat_numbers.json" > "$tmp_file" && mv "$tmp_file" "${folder}/tmp/vat_numbers.json"
                        echo "Found VAT numbers for PIC $pic: $vat_numbers"
                        success=1
                        break
                    fi
                fi
            fi
        fi
    done

    if [ $success -eq 0 ]; then
        echo "No VAT numbers found for PIC $pic (URL: $url)"
        # Get the effective URL after redirects with same cleaning as successful attempts
        if effective_url=$(curl -kL --max-time 15 -o /dev/null -w '%{url_effective}\n' "$url" 2>/dev/null | head -n1); then
            effective_url=$(echo "$effective_url" | tr -d '\n' | grep -E '^https?://' || echo "NA")
        else
            effective_url="NA"
        fi
        echo "Final effective URL for failed attempt: $effective_url"

        # Update or add entry with empty VAT number
        tmp_file="${folder}/tmp/vat_numbers_tmp.json"
        jq --arg pic "$pic" --arg url "$url" --arg eff_url "$effective_url" '
            (map(select(.pic != $pic)) + [{
                "pic": $pic,
                "vat_numbers": "",
                "source_url": $url,
                "effective_url": $eff_url
            }]) | sort_by(.pic)
        ' "${folder}/tmp/vat_numbers.json" > "$tmp_file" && mv "$tmp_file" "${folder}/tmp/vat_numbers.json"
    fi

    # Add delay to respect LLM rate limit (13 requests/minute max)
    sleep 5

done < "${folder}"/tmp/italian_participants.jsonl

# Move final results to output location
mv "${folder}"/tmp/vat_numbers.json "$vat_file"
