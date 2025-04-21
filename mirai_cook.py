# -*- coding: utf-8 -*-
"""
Entry point principale per l'applicazione Streamlit Mirai Cook.
Questo script definisce la pagina Home/Benvenuto e le configurazioni generali dell'app.
La logica delle singole pagine si trova nella cartella 'pages/'.
"""

import streamlit as st
# Importa altre librerie necessarie per configurazioni globali se servono
# import os
# from dotenv import load_dotenv

# --- Configurazione Pagina Streamlit ---
# NOTA: st.set_page_config() deve essere il primo comando Streamlit eseguito.
st.set_page_config(
    page_title="Mirai Cook AI",
    page_icon="🍳",  # Puoi scegliere un'emoji o un URL di un'icona
    layout="wide", # Usa l'intera larghezza della pagina
    initial_sidebar_state="expanded" # Mostra la sidebar all'avvio
)

# --- Caricamento Configurazioni Iniziali (Opzionale) ---
# Se hai configurazioni globali o vuoi caricare .env subito
# load_dotenv()
# print("Variabili d'ambiente caricate.") # Per debug

# --- Contenuto Pagina Home ---

st.title("Benvenuto in Mirai Cook! 🍳🤖")

st.markdown("""
Il tuo assistente culinario personale potenziato dall'Intelligenza Artificiale.

**Esplora le sezioni usando il menu nella barra laterale a sinistra:**

* **Ricettario:** Sfoglia, cerca e visualizza le tue ricette salvate.
* **Aggiungi/Modifica:** Inserisci manualmente nuove ricette o modificane di esistenti.
* **Importa Ricetta:** Aggiungi ricette digitalizzandole da immagini/PDF o importandole da URL.
* **Gestione Dispensa:** Tieni traccia degli ingredienti che hai a disposizione.
* **Gestione Ingredienti:** Visualizza e gestisci la lista principale degli ingredienti conosciuti dall'app.
* **Suggerimenti AI:** Chiedi all'AI cosa cucinare basandosi sul tuo ricettario e sulla tua dispensa, oppure fatti generare ricette completamente nuove.
* **Ricerca Avanzata:** Utilizza la potenza di Azure AI Search per trovare ricette nel tuo database.

*(Questa è la pagina principale. La logica specifica di ogni sezione si trova nei file corrispondenti nella cartella `pages/`)*
""")

# Puoi aggiungere un'immagine di benvenuto se vuoi
# try:
#     st.image("path/to/your/welcome_image.png", use_column_width=True)
# except FileNotFoundError:
#     st.warning("Immagine di benvenuto non trovata.")

st.sidebar.success("Seleziona una pagina qui sopra.")

# --- Logica Aggiuntiva della Pagina Home (se necessaria) ---
# Ad esempio, potresti mostrare un riepilogo, le ultime ricette aggiunte, ecc.
# Ma mantieni questo file snello, la logica principale va nelle altre pagine.

# --- Esempio di inizializzazione Session State (se serve uno stato globale) ---
# if 'app_initialized' not in st.session_state:
#     st.session_state['app_initialized'] = True
#     st.session_state['user_id'] = "default_user" # Per ora, single user
#     # Inizializza altre variabili di stato globali se necessario
#     print("Stato sessione inizializzato.")


# Ricorda: La maggior parte del codice UI e della logica andrà nei file
# dentro la cartella 'pages/' e nei moduli dentro 'src/'.
