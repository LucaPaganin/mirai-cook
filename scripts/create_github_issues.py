import requests
import json
import os
import time # Per piccole pause tra le richieste API
from dotenv import load_dotenv
# Carica le variabili d'ambiente dal file .env
load_dotenv()

GITHUB_GRAPHQL_URL = "https://api.github.com/graphql"
GITHUB_PAT = os.environ.get("GITHUB_PAT")
REPOSITORY_ID = os.environ.get("REPOSITORY_ID") # ID del repository GitHub (da sostituire con il tuo)

# --- DEFINIZIONE DEI TASK (Basata sulla nostra discussione) ---
# Struttura: Lista di Epic, ogni Epic è un dizionario con 'title', 'estimate', 'tasks' (lista di Task)
# Ogni Task è un dizionario con 'title', 'estimate', 'body' (opzionale, descrizione aggiuntiva)

project_structure = [
    # --- EPIC 1 ---
    {
        "title": "[EPIC] 1: Setup Iniziale & Infrastruttura Azure",
        "estimate": "4-7h",
        "tasks": [
            {"title": "1.1 Creare repository GitHub con README, .gitignore, licenza", "estimate": "0.5h"},
            {"title": "1.2 Setup ambiente Python locale (venv, pip, requirements.txt iniziale)", "estimate": "0.5h"},
            {"title": "1.3 Creare Gruppo di Risorse Azure", "estimate": "0.5h"},
            {"title": "1.4 Creare Azure Key Vault e policy accesso iniziali", "estimate": "1-1.5h"},
            {"title": "1.5 Creare/Configurare Managed Identity (per App Service/ACA) o Service Principal", "estimate": "1-2h"},
            {"title": "1.6 Setup base progetto Streamlit (app.py, config)", "estimate": "0.5h"},
        ]
    },
    # --- EPIC 2 ---
    {
        "title": "[EPIC] 2: Backend - Persistenza Dati (Cosmos DB + Pydantic)",
        "estimate": "10-17h",
        "tasks": [
            {"title": "2.1 Creare Account Azure Cosmos DB (NoSQL API, Free Tier/Serverless)", "estimate": "0.5-1h"},
            {"title": "2.2 Definire modelli Pydantic (Recipe, IngredientItem, IngredientEntity, Pantry)", "estimate": "1-2h"},
            {"title": "2.3 Definire schema DB e creare Containers (Recipes, Pantry, IngredientsMasterList) con Partition Keys", "estimate": "1h"},
            {"title": "2.4 Implementare funzioni CRUD Ricette (Python SDK + Pydantic)", "estimate": "3-5h"},
            {"title": "2.5 Implementare funzioni Get/Update Dispensa (Lista ID) (Python SDK + Pydantic)", "estimate": "1-2h"}, # Semplificato
            {"title": "2.6 Implementare logica Get/Update IngredientEntity (incl. check esatto/similarità + HITL prompt + cache calorie)", "estimate": "3-6h"}, # Logica raffinata
            {"title": "2.7 Integrare recupero credenziali da Key Vault via azure-identity", "estimate": "1h"},
        ]
    },
    # --- EPIC 3 ---
     {
        "title": "[EPIC] 3: Backend - Integrazione Servizi AI & Logica Core",
        "estimate": "49-96h", # Stima Epic ampia
        "tasks": [
            # DI
            {"title": "3.1.1 [DI] Creare/Configurare risorsa AI Services/DI", "estimate": "0.5h"},
            {"title": "3.1.2 [DI] (Opz.) Addestrare/Deployare modello custom ricette (*Escluso labeling*)", "estimate": "1-2h"},
            {"title": "3.1.3 [DI] Integrare SDK DI per analisi immagini ricetta", "estimate": "2-4h"},
            {"title": "3.1.4 [DI] Collegare output DI a UI Streamlit per verifica HITL", "estimate": "1-2h"},
            # Lang
            {"title": "3.2.1 [Lang] Creare/Configurare risorsa AI Services/Language", "estimate": "0.5h"},
            {"title": "3.2.2 [Lang] (Se Custom) Addestrare/Deployare modello custom classificazione (*Escluso labeling*)", "estimate": "1-2h"},
            {"title": "3.2.3 [Lang] Integrare SDK Language per classificazione (custom o zero-shot)", "estimate": "1.5-3h"},
            {"title": "3.2.4 [Lang] Integrare risultato+HITL nel salvataggio ricetta", "estimate": "0.5-1h"},
             # Vision
            {"title": "3.3.1 [Vision] Creare/Configurare risorsa AI Services/Vision", "estimate": "0.5h"},
            {"title": "3.3.2 [Vision] Creare/Configurare Azure Blob Storage per immagini piatti", "estimate": "0.5h"},
            {"title": "3.3.3 [Vision] Integrare SDK Vision (Analyze Image: Tags, Caption, Crop)", "estimate": "1.5-3h"},
            {"title": "3.3.4 [Vision] Logica upload/salvataggio foto (Blob) e metadati (Cosmos)", "estimate": "0.5-1h"},
            # Speech
            {"title": "3.4.1 [Speech] Creare/Configurare risorsa AI Services/Speech", "estimate": "0.5h"},
            {"title": "3.4.2 [Speech] Implementare TTS (Read Aloud) con SDK e st.audio", "estimate": "2-4h"},
            {"title": "3.4.3 [Speech] (Se Live STT) Setup input audio live (streamlit-webrtc?)", "estimate": "2-4h"},
            {"title": "3.4.4 [Speech] Integrare SDK STT (streaming o file)", "estimate": "2-4h"},
            {"title": "3.4.5 [Speech] Collegare output STT a UI + HITL", "estimate": "0.5-2h"},
            # OpenAI Direct
            {"title": "3.5.1 [OpenAI] Creare risorsa Azure OpenAI e deployare modello GPT", "estimate": "0.5-1h"},
            {"title": "3.5.2 [OpenAI] Integrare SDK azure-openai per chiamata diretta (Generazione Nuova Ricetta)", "estimate": "1-2h"},
            {"title": "3.5.3 [OpenAI] Prompt engineering generazione nuova ricetta", "estimate": "0.5-1h"},
            # SK Agent
            {"title": "3.6.1 [SK] Setup libreria Semantic Kernel", "estimate": "0.5-1h"},
            {"title": "3.6.2 [SK] Creare Plugin SK custom per query Cosmos DB (Tool Ricerca Ricette)", "estimate": "1.5-3h"},
            {"title": "3.6.3 [SK] Definire prompt/funzione/plan per agente suggerimento ricetta", "estimate": "2-4h"},
            {"title": "3.6.4 [SK] Integrare invocazione agente SK in Streamlit", "estimate": "1-2h"},
             # AI Search
            {"title": "3.7.1 [Search] Creare risorsa Azure AI Search", "estimate": "0.5h"},
            {"title": "3.7.2 [Search] Definire Index Schema", "estimate": "1-2h"},
            {"title": "3.7.3 [Search] Configurare Data Source (Cosmos DB)", "estimate": "0.5-1h"},
            {"title": "3.7.4 [Search] (Opz.) Creare Skillset (es. Key Phrases)", "estimate": "1-3h"},
            {"title": "3.7.5 [Search] Creare/Eseguire Indexer", "estimate": "0.5-1h"},
            {"title": "3.7.6 [Search] Integrare SDK Search per query e facet", "estimate": "3-5h"},
             # Calorie Calc
            {"title": "3.8.1 [Calorie] Ricerca/Scelta API DB Alimentare Gratuita", "estimate": "1-2h"},
            {"title": "3.8.2 [Calorie] Implementare Funzione Lookup API Esterna", "estimate": "1.5-3h"},
            {"title": "3.8.3 [Calorie] Implementare Logica Calcolo (da input strutturato + cache + conversioni base)", "estimate": "1-2h"},
            {"title": "3.8.4 [Calorie] Gestire Casi Ingredienti Non Trovati/Aggiornare cache in Master List", "estimate": "0.5-1h"}, # Aggiunto aggiornamento cache
            # URL Import
            {"title": "3.9.1 [Import] Integrare recipe-scrapers", "estimate": "1.5-3h"},
            {"title": "3.9.2 [Import] Implementare fallback estrazione testo", "estimate": "1-2h"},
            {"title": "3.9.3 [Import] Implementare chiamata/prompt OpenAI per strutturare testo fallback", "estimate": "1-2h"},
            {"title": "3.9.4 [Import] Collegare output scraper/AI a UI per verifica HITL", "estimate": "1.5-3h"},
            # Shopping List
            {"title": "3.10.1 [Shopping] Implementare calcolo set difference + aggregazione quantità", "estimate": "0.5-1.5h"},
            {"title": "3.10.2 [Shopping] Preparare output per UI (con avviso 'Verifica scorta!') e download", "estimate": "0.5-1.5h"},
        ]
    },
    # --- EPIC 4 ---
    {
        "title": "[EPIC] 4: Frontend - Streamlit UI",
        "estimate": "18-40h", # Aumentato leggermente per complessità HITL e gestione ingredienti
        "tasks": [
            {"title": "4.1 Struttura generale app (navigazione, multi-pagina/sezioni)", "estimate": "2-4h"},
            {"title": "4.2 UI Visualizzazione Dettaglio Ricetta (testo, img, categorie, metadati, calorie stimate)", "estimate": "2-4h"},
            {"title": "4.3 UI Browse/Filtering Ricettario (incl. categorie/facet Search)", "estimate": "2-4h"},
            {"title": "4.4 UI Gestione Dispensa (lista ID, es. con multiselect)", "estimate": "1-3h"}, # Semplificato
            {"title": "4.5 UI Aggiunta/Modifica Ricetta (Manuale + Campi Strutturati Ing. + HITL per DI/Classificazione/Import URL)", "estimate": "4-7h"}, # Più complessa
            {"title": "4.6 UI Gestione IngredientEntity Master (CRUD con st.data_editor?)", "estimate": "4-8h"},
            {"title": "4.7 UI per Input/Output AI (Dettatura, Lettura, Upload Img, Prompt Gen., Import URL)", "estimate": "2-4h"},
            {"title": "4.8 UI Ricerca Avanzata (Barra, Filtri Facet, Risultati)", "estimate": "1.5-3h"},
            {"title": "4.9 UI Visualizzazione Stima Calorie e Bottone Download Lista Spesa", "estimate": "1-2h"},
            {"title": "4.10 Miglioramenti UX/UI generali e test/ottimizzazione mobile", "estimate": "2-5h"},
        ]
    },
    # --- EPIC 5 ---
    {
        "title": "[EPIC] 5: Deployment & Testing Finale",
        "estimate": "5-10h",
        "tasks": [
             {"title": "5.1 Creare Dockerfile per app Streamlit", "estimate": "1-2h"},
             {"title": "5.2 Creare e configurare Azure App Service (o ACA) con Managed Identity", "estimate": "1-2h"},
             {"title": "5.3 Configurare pipeline CI/CD (Opzionale)", "estimate": "1-3h"},
             {"title": "5.4 Configurare segreti Key Vault e permessi Managed Identity nel deployment Azure", "estimate": "0.5-1h"},
             {"title": "5.5 Test end-to-end e debugging post-deployment", "estimate": "2-4h"},
        ]
    },
]


# --- Funzione Helper per Creare Issue ---
def create_github_issue(repo_id, title, body, labels=None):
    """Crea una issue GitHub usando l'API GraphQL."""
    if not GITHUB_PAT:
        print("ERRORE: GITHUB_PAT non impostato.")
        return None

    # Nota: La mutation potrebbe richiedere aggiustamenti se vuoi passare label IDs etc.
    # Questa versione base passa solo title e body.
    mutation = """
    mutation CreateIssue($repoId: ID!, $title: String!, $body: String) {
      createIssue(input: {repositoryId: $repoId, title: $title, body: $body}) {
        issue {
          id
          number
          url
          title
        }
      }
    }
    """
    variables = {
        "repoId": repo_id,
        "title": title,
        "body": body
        # Se vuoi aggiungere label, devi passare un array di Node ID delle label:
        # "labelIds": ["LABEL_NODE_ID_1", "LABEL_NODE_ID_2"]
    }
    headers = {
        "Authorization": f"bearer {GITHUB_PAT}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    payload = {"query": mutation, "variables": variables}

    # Aggiungiamo un retry semplice in caso di errori temporanei dell'API
    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = requests.post(GITHUB_GRAPHQL_URL, headers=headers, json=payload, timeout=30) # Timeout aggiunto
            response.raise_for_status()
            response_data = response.json()

            if "errors" in response_data:
                print(f"ERRORE GraphQL per '{title}' (Attempt {attempt+1}/{max_retries}): {response_data['errors']}")
                if attempt == max_retries - 1: return None # Fallito dopo tutti i retry
                time.sleep(2 ** attempt) # Exponential backoff
                continue # Riprova

            elif "data" in response_data and response_data["data"].get("createIssue") and response_data["data"]["createIssue"].get("issue"):
                 return response_data["data"]["createIssue"]["issue"]
            else:
                print(f"Risposta inattesa per '{title}' (Attempt {attempt+1}/{max_retries}): {response_data}")
                if attempt == max_retries - 1: return None
                time.sleep(2 ** attempt)
                continue
        except requests.exceptions.Timeout:
             print(f"TIMEOUT per '{title}' (Attempt {attempt+1}/{max_retries})")
             if attempt == max_retries - 1: return None
             time.sleep(2 ** attempt) # Exponential backoff
        except requests.exceptions.RequestException as e:
            print(f"ERRORE HTTP per '{title}' (Attempt {attempt+1}/{max_retries}): {e}")
            # Potrebbe non valer la pena riprovare per tutti gli errori HTTP, ma lo facciamo per semplicità
            if attempt == max_retries - 1: return None
            time.sleep(2 ** attempt)
        except json.JSONDecodeError:
            print(f"ERRORE JSON Decode per '{title}'. Risposta: {response.text}")
            return None # Non riprovare per JSON malformato
    return None # Fallito dopo tutti i retry

# --- Logica Principale ---
if __name__ == "__main__":
    print("--- Creazione Issues GitHub per Mirai Cook ---")

    epic_issue_map = {} # Dizionario per mappare titolo Epic -> numero Issue creata

    # 1. Crea gli Epic
    print("\n[FASE 1] Creazione Issues EPIC...")
    for epic_data in project_structure:
        epic_title = epic_data["title"]
        epic_body = f"**Stima Totale Epic:** {epic_data.get('estimate', 'N/D')}\n\n*(Questo è un Epic che raggruppa i task sottostanti)*"
        print(f"  Creando Epic: {epic_title}...")
        created_epic = create_github_issue(REPOSITORY_ID, epic_title, epic_body)
        if created_epic:
            epic_issue_map[epic_title] = created_epic["number"]
            print(f"    -> Creato: #{created_epic['number']} - {created_epic['url']}")
        else:
            print(f"    -> ERRORE nella creazione dell'Epic '{epic_title}'.")
        time.sleep(1.5) # Pausa leggermente più lunga tra le issue

    # 2. Crea i Task figli, referenziando gli Epic
    print("\n[FASE 2] Creazione Issues TASK Figli...")
    for epic_data in project_structure:
        parent_epic_title = epic_data["title"]
        parent_issue_number = epic_issue_map.get(parent_epic_title)

        if not parent_issue_number:
            print(f"\n  ATTENZIONE: Impossibile creare task per Epic '{parent_epic_title}' perché l'Epic non è stato creato o mappato.")
            continue

        print(f"\n  Creando Tasks per Epic #{parent_issue_number} - {parent_epic_title}...")
        for task_data in epic_data.get("tasks", []):
            task_title = task_data["title"]
            task_body = f"**Stima Task:** {task_data.get('estimate', 'N/D')}\n\n"
            if "body" in task_data:
                 task_body += task_data["body"] + "\n\n"
            task_body += f"Parent Epic: #{parent_issue_number}"

            print(f"    Creando Task: {task_title}...")
            created_task = create_github_issue(REPOSITORY_ID, task_title, task_body)
            if created_task:
                 print(f"      -> Creato: #{created_task['number']} - {created_task['url']}")
            else:
                 print(f"      -> ERRORE nella creazione del Task '{task_title}'.")
            time.sleep(1.5) # Pausa

    print("\n--- Creazione Issues Completata ---")