# MirAI Cook 🍳🤖

**Il tuo assistente culinario AI personale e intelligente.**

Mirai Cook è un'applicazione web progettata per essere un ricettario digitale avanzato e un aiuto in cucina, sfruttando la potenza dei servizi AI di Microsoft Azure. Permette di gestire ricette, digitalizzarle da immagini o importarle da URL, tenere traccia della dispensa, ricevere suggerimenti personalizzati, generare liste della spesa, interagire vocalmente e molto altro.

[![Status Badge Placeholder](https://img.shields.io/badge/status-in%20development-orange)](https://github.com/LucaPaganin/mirai-cook) 
## ✨ Funzionalità Principali

* **Ricettario Digitale:** Database cloud (Azure Cosmos DB) per salvare e organizzare le tue ricette.
* **Inserimento Multi-modalità:** Aggiungi ricette manualmente, digitalizzale da foto/scansioni (con Azure AI Document Intelligence + HITL), o importale da URL (con `recipe-scrapers` + AI Fallback + HITL).
* **Gestione Dispensa:** Tieni traccia degli ingredienti che hai a casa.
* **Master List Ingredienti:** Gestione centralizzata degli ingredienti conosciuti con caching calorie e controllo duplicati/similarità.
* **Categorizzazione Automatica:** Classifica le ricette per portata (Antipasto, Primo...) usando Azure AI Language (con conferma utente HITL).
* **Analisi Foto Piatti:** Associa foto ai piatti e ottieni tag/descrizioni automatiche con Azure AI Vision.
* **Stima Calorie:** Calcolo approssimativo delle calorie basato su database alimentare esterno e cache locale.
* **Suggerimenti AI (dal Ricettario):** Un agente AI (Semantic Kernel + Azure OpenAI) suggerisce ricette dal tuo ricettario basate sulla tua dispensa.
* **Generazione Nuove Ricette:** Chiedi ad Azure OpenAI di creare ricette inedite su misura.
* **Lista della Spesa:** Genera automaticamente la lista degli ingredienti mancanti per le ricette scelte (con opzione download).
* **Interazione Vocale:** Detta ingredienti/istruzioni (Speech-to-Text) e ascolta le ricette (Text-to-Speech) usando Azure AI Speech.
* **Ricerca Avanzata:** Trova ricette nel tuo ricettario usando Azure AI Search con ricerca testuale e filtri/facet.
* **UI Intuitiva:** Interfaccia web sviluppata con Streamlit, ottimizzata per mobile.
* **Sicurezza:** Gestione sicura delle credenziali tramite Azure Key Vault e Managed Identity/Service Principal.
* **Cloud-Native:** Progettato per il deployment su Azure (App Service / Container Apps).

## 🛠️ Tech Stack

* **Linguaggio:** Python 3.9+
* **Framework UI:** Streamlit
* **Database:** Azure Cosmos DB (API NoSQL)
* **Storage Oggetti:** Azure Blob Storage
* **AI Services:**
    * Azure AI Services (Risorsa Unificata per Vision, Language, Speech, Document Intelligence)
    * Azure OpenAI Service (GPT-3.5/GPT-4)
    * Azure AI Search
* **Orchestrazione AI:** Microsoft Semantic Kernel
* **Gestione Segreti:** Azure Key Vault
* **Identità Applicazione:** Azure Managed Identity / Service Principal
* **Deployment:** Docker, Azure App Service / Azure Container Apps

## 🚀 Setup e Installazione Locale

*(Sezione da dettagliare)*

1.  **Clona il Repository:**
    ```bash
    git clone [https://github.com/LucaPaganin/mirai-cook.git](https://github.com/LucaPaganin/mirai-cook.git)
    cd mirai-cook
    ```
2.  **Crea Ambiente Virtuale:**
    ```bash
    python -m venv .venv
    source .venv/bin/activate  # Linux/macOS
    # oppure
    # .\.venv\Scripts\activate  # Windows
    ```
3.  **Installa Dipendenze:**
    ```bash
    pip install -r requirements.txt
    ```
4.  **Configura Variabili d'Ambiente:**
    * Copia `.env.example` in `.env`.
    * Compila il file `.env` con le tue credenziali Azure (Key Vault URI, SP/Managed Identity details o chiavi dirette per test locali se necessario). **Non committare mai il file `.env`!**
5.  **Avvia l'App Streamlit:**
    ```bash
    streamlit run app/mirai_cook.py
    ```

## ☁️ Deployment

*(Sezione da dettagliare)*

L'applicazione è progettata per essere containerizzata con Docker e deployata su Azure App Service o Azure Container Apps. Sarà necessario configurare le variabili d'ambiente come segreti nella piattaforma di hosting e assicurarsi che l'identità gestita (o il service principal) abbia i permessi corretti sulle risorse Azure (Key Vault, Cosmos DB, etc.).

Vedi il file `Dockerfile` e potenziali script di deployment o pipeline CI/CD.

## 📖 Utilizzo

*(Sezione da dettagliare con screenshot o GIF animate)*

Descrivere brevemente come usare le funzionalità principali: aggiungere ricette, gestire la dispensa, ottenere suggerimenti, ecc.

## 🤝 Contributing

*(Se applicabile, aggiungere linee guida per contributi)*

## 📄 Licenza

Questo progetto è rilasciato sotto la Licenza MIT. Vedi il file `LICENSE` per i dettagli.

