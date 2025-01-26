# Log di progetto

## 2025-01-26
- Creato script `progetti_finanziati.sh` per scaricare i dati dei progetti EDF finanziati
- Implementato:
  - Controllo dipendenze (curl, jq, flatterer)
  - Scaricamento paginato dei dati dall'API
  - Elaborazione JSON con jq
  - Appiattimento dati con flatterer
  - Creazione struttura directory per dati grezzi, elaborati e finali
- Dati salvati in:
  - `data/progetti_finanziati/raw/`: file JSON grezzi per pagina
  - `data/progetti_finanziati/processing/`: file JSON elaborati
  - `data/progetti_finanziati/output/`: file JSON consolidato e dati appiattiti

## Prossimi passi
- [ ] Aggiungere validazione dei dati scaricati
- [ ] Creare script per aggiornamento incrementale
- [ ] Implementare sistema di notifiche per errori
- [ ] Documentare struttura dei dati
