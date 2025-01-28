# Script di Elaborazione Dati

## progetti_finanziati.sh
Script per il download e l'elaborazione dei dati sui progetti finanziati dall'UE. Lo script:
- Scarica i dati paginati dall'API della Commissione Europea
- Elabora i dati JSON dei partecipanti
- Unifica tutti i file in un unico dataset
- Appiattisce la struttura dei dati per facilitarne l'analisi

## p_iva_scrape.sh 
Script per l'estrazione delle Partite IVA dai siti web dei partecipanti italiani. Lo script:
- Filtra i partecipanti italiani dal dataset principale
- Visita i siti web di ogni partecipante
- Utilizza un modello LLM per estrarre le Partite IVA dalle pagine web
- Salva i risultati in un file JSON con PIC, URL e Partite IVA trovate
