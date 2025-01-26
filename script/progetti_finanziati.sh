#!/bin/bash

# Imposta opzioni di sicurezza e debugging
set -x    # Debug: mostra ogni comando eseguito
set -e    # Esci immediatamente se un comando fallisce
set -u    # Considera variabili non definite come errore
set -o pipefail  # Considera l'intera pipeline come fallita se un comando fallisce

# Verifica dipendenze necessarie
for program in curl jq flatterer; do
    if ! command -v "$program" >/dev/null 2>&1; then
        echo "Errore: $program non è installato"
        exit 1
    fi
done

# Imposta percorsi delle directory
folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Crea struttura delle directory
mkdir -p "${folder}"/../data/progetti_finanziati
mkdir -p "${folder}"/../data/progetti_finanziati/{raw,output,processing}
mkdir -p "${folder}"/../data/sample

# Ottieni il conteggio totale dei progetti finanziati
conteggio=$(curl 'https://api.tech.ec.europa.eu/search-api/prod/rest/search?apiKey=SEDIA_NONH2020_PROD&text=***&pageSize=1&pageNumber=1' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: it,en-US;q=0.9,en;q=0.8' -H 'Cache-Control: No-Cache' -H 'Connection: keep-alive' -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryuBnndOmJO94KT19m' -H 'Origin: https://ec.europa.eu' -H 'Referer: https://ec.europa.eu/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36' -H 'X-Requested-With: XMLHttpRequest' -H 'sec-ch-ua: "Not A(Brand";v="8", "Chromium";v="132", "Google Chrome";v="132"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' --data-raw $'------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="sort"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"order":"DESC","field":"title"}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="query"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"bool":{"must":[{"terms":{"programId":["44181033"]}}]}}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="languages"; filename="blob"\r\nContent-Type: application/json\r\n\r\n["en"]\r\n------WebKitFormBoundaryuBnndOmJO94KT19m--\r\n' | jq '.totalResults')

# Calcola il numero totale di pagine (50 risultati per pagina)
pages=$(( (conteggio + 49) / 50 ))

# Scarica i dati paginati dall'API
for ((page=1; page<=pages; page++))
do
    # Formatta il numero di pagina con zero padding (es. 01, 02, ...)
    page_num=$(printf "%02d" $page)

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Scaricando pagina $page di $pages..."

    curl 'https://api.tech.ec.europa.eu/search-api/prod/rest/search?apiKey=SEDIA_NONH2020_PROD&text=***&pageSize=50&pageNumber='"$page" -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: it,en-US;q=0.9,en;q=0.8' -H 'Cache-Control: No-Cache' -H 'Connection: keep-alive' -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryuBnndOmJO94KT19m' -H 'Origin: https://ec.europa.eu' -H 'Referer: https://ec.europa.eu/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36' -H 'X-Requested-With: XMLHttpRequest' -H 'sec-ch-ua: "Not A(Brand";v="8", "Chromium";v="132", "Google Chrome";v="132"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' --data-raw $'------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="sort"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"order":"DESC","field":"title"}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="query"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"bool":{"must":[{"terms":{"programId":["44181033"]}}]}}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="languages"; filename="blob"\r\nContent-Type: application/json\r\n\r\n["en"]\r\n------WebKitFormBoundaryuBnndOmJO94KT19m--\r\n' > "${folder}"/../data/progetti_finanziati/raw/progetti_finanziati_"$page_num".json

    # rendi leggibili i dati sui partecipanti
    cat "${folder}"/../data/progetti_finanziati/raw/progetti_finanziati_"$page_num".json | jq '.results|map(.metadata.participants |= (if type == "array" then map(fromjson)[0] else . end))' > "${folder}"/../data/progetti_finanziati/processing/progetti_finanziati_"$page_num".json

    # Aggiungi un ritardo per evitare di sovraccaricare il server API
    sleep 1
done

# Unisci tutti i file JSON scaricati in un unico file
jq -s 'add'  "${folder}"/../data/progetti_finanziati/processing/progetti_finanziati_*.json >"${folder}"/../data/progetti_finanziati/output/progetti_finanziati.json

# Appiattisci la struttura JSON per l'analisi dati
flatterer --force "${folder}"/../data/progetti_finanziati/output/progetti_finanziati.json "${folder}"/../data/progetti_finanziati/output/flattened

