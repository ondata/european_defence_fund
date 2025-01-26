# Introduzione

I dati del "EU Funding & Tenders Portal" sono accessibili via API:

<https://ec.europa.eu/info/funding-tenders/opportunities/portal/screen/support/apis>

Questo progetto è dedicato all'analisi dei fondi del European Defence Fund (EDF).

## Info utili per le query via API

Il program ID dell'EDF è `44181033`. Nome parametro: `programId`.

- Status (Stato della chiamata). Nome parametro: `status`
  - **Closed**: 31094503 (Chiuso)
  - **Forthcoming**: 31094501 (In arrivo)
  - **Open**: 31094502 (Aperto)
- Type (Tipo di bando). Nome parametro: `type`
  - **Tender**: 0 (Gara d'appalto)
  - **Grant**: 1 (Sovvenzione)
  - **Cascade funding calls**: 8 (Chiamate a cascata per finanziamenti)

## File utili

- [most frequently used code list for search fields](../risorse/basic_code_list.xlsx)
- [sample set of postman requests](../risorse/postman_collection.json)

## Query di esempio

### Call for proposal EDF

```bash
curl -X POST "https://api.tech.ec.europa.eu/search-api/prod/rest/search?apiKey=SEDIA&text=*&pageSize=10&pageNumber=1" \
-H "Accept: application/json" \
-H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryy1GDmA6K9XgadGF4" \
--data-raw $'------WebKitFormBoundaryy1GDmA6K9XgadGF4\r\nContent-Disposition: form-data; name="query"\r\nContent-Type: application/json\r\n\r\n{"bool":{"must":[{"terms":{"status":["31094501","31094502","31094503"]}},{"terms":{"type":["0","1","8"]}},{"term":{"frameworkProgramme":"44181033"}}]}}\r\n------WebKitFormBoundaryy1GDmA6K9XgadGF4--\r\n'
```

### Tutti i progetti EDF finanziati

```bash
curl 'https://api.tech.ec.europa.eu/search-api/prod/rest/search?apiKey=SEDIA_NONH2020_PROD&text=***&pageSize=50&pageNumber=1' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: it,en-US;q=0.9,en;q=0.8' -H 'Cache-Control: No-Cache' -H 'Connection: keep-alive' -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryuBnndOmJO94KT19m' -H 'Origin: https://ec.europa.eu' -H 'Referer: https://ec.europa.eu/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36' -H 'X-Requested-With: XMLHttpRequest' -H 'sec-ch-ua: "Not A(Brand";v="8", "Chromium";v="132", "Google Chrome";v="132"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' --data-raw $'------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="sort"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"order":"DESC","field":"title"}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="query"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"bool":{"must":[{"terms":{"programId":["44181033"]}}]}}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="languages"; filename="blob"\r\nContent-Type: application/json\r\n\r\n["en"]\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="displayFields"; filename="blob"\r\nContent-Type: application/json\r\n\r\n["title","programId","projectId","acronym","participants","programAbbreviation","programmes","status","objective","topicAbbreviation"]\r\n------WebKitFormBoundaryuBnndOmJO94KT19m--\r\n'
```

La stessa query, ma con tutti i campi disponibili (sopra ne sono stati selezionati solo alcuni):

```bash
curl 'https://api.tech.ec.europa.eu/search-api/prod/rest/search?apiKey=SEDIA_NONH2020_PROD&text=***&pageSize=50&pageNumber=1' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: it,en-US;q=0.9,en;q=0.8' -H 'Cache-Control: No-Cache' -H 'Connection: keep-alive' -H 'Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryuBnndOmJO94KT19m' -H 'Origin: https://ec.europa.eu' -H 'Referer: https://ec.europa.eu/' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-site' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36' -H 'X-Requested-With: XMLHttpRequest' -H 'sec-ch-ua: "Not A(Brand";v="8", "Chromium";v="132", "Google Chrome";v="132"' -H 'sec-ch-ua-mobile: ?0' -H 'sec-ch-ua-platform: "Windows"' --data-raw $'------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="sort"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"order":"DESC","field":"title"}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="query"; filename="blob"\r\nContent-Type: application/json\r\n\r\n{"bool":{"must":[{"terms":{"programId":["44181033"]}}]}}\r\n------WebKitFormBoundaryuBnndOmJO94KT19m\r\nContent-Disposition: form-data; name="languages"; filename="blob"\r\nContent-Type: application/json\r\n\r\n["en"]\r\n------WebKitFormBoundaryuBnndOmJO94KT19m--\r\n'
```
