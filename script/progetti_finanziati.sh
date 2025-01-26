#!/bin/bash

set -x
set -e
set -u
set -o pipefail

# Verifica che i programmi necessari siano installati
for program in curl jq; do
    if ! command -v "$program" >/dev/null 2>&1; then
        echo "Errore: $program non è installato"
        exit 1
    fi
done

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/../data/progetti_finanziati
mkdir -p "$folder"/../data/progetti_finanziati/raw
mkdir -p "$folder"/../data/sample

curl 'https://api.tech.ec.europa.eu/search-api/prod/rest/search?apiKey=SEDIA_NONH2020_PROD&text=***&pageSize=50&pageNumber=1' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: it,en-US;q=0.9,en;q=0.8' -H 'Cache-Control: No-Cache' -H 'Connection: keep-alive' -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryuBnndOmJO94KT19m' -H 'Origin: https://ec.europa.eu' -H 'Referer: https://ec.europa.eu/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36' -H 'X-Requested-With: XMLHttpRequest' -H 'sec-ch-ua: "Not A(Brand";v="8", "Chromium";v="132", "Google Chrome";v="132"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' --data-raw $'------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="sort"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"order":"DESC","field":"title"}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="query"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"bool":{"must":[{"terms":{"programId":["44181033"]}}]}}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="languages"; filename="blob"\r\nContent-Type: application/json\r\n\r\n["en"]\r\n------WebKitFormBoundaryuBnndOmJO94KT19m--\r\n' > "$folder"/../data/progetti_finanziati/raw/progetti_finanziati.json

# Crea un file di esempio con i primi 3 risultati
jq '.results[0:3] | map(.metadata.participants |= fromjson)' "$folder"/../data/progetti_finanziati/raw/progetti_finanziati.json > "$folder"/../data/sample/progetti_finanziati_sample.json
