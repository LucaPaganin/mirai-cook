import requests
import json
import os
import time # For small pauses between API requests
from dotenv import load_dotenv
# Load environment variables from the .env file
load_dotenv()

GITHUB_GRAPHQL_URL = "https://api.github.com/graphql"
GITHUB_PAT = os.environ.get("GITHUB_PAT")
REPOSITORY_ID = os.environ.get("REPOSITORY_ID") # GitHub repository ID (replace with yours)

# --- TASK DEFINITION (Based on our discussion) ---
# Structure: List of Epics, each Epic is a dict with 'title', 'estimate', 'tasks' (list of Tasks)
# Each Task is a dict with 'title', 'estimate', 'body' (optional, additional description)

project_structure = [
    # --- EPIC 1 ---
    {
        "title": "[EPIC] 1: Initial Setup & Azure Infrastructure",
        "estimate": "4-7h",
        "tasks": [
            {"title": "1.1 Create GitHub repository with README, .gitignore, license", "estimate": "0.5h"},
            {"title": "1.2 Setup local Python environment (venv, pip, initial requirements.txt)", "estimate": "0.5h"},
            {"title": "1.3 Create Azure Resource Group", "estimate": "0.5h"},
            {"title": "1.4 Create Azure Key Vault and initial access policies", "estimate": "1-1.5h"},
            {"title": "1.5 Create/Configure Managed Identity (for App Service/ACA) or Service Principal", "estimate": "1-2h"},
            {"title": "1.6 Basic Streamlit project setup (app.py, config)", "estimate": "0.5h"},
        ]
    },
    # --- EPIC 2 ---
    {
        "title": "[EPIC] 2: Backend - Data Persistence (Cosmos DB + Pydantic)",
        "estimate": "10-17h",
        "tasks": [
            {"title": "2.1 Create Azure Cosmos DB Account (NoSQL API, Free Tier/Serverless)", "estimate": "0.5-1h"},
            {"title": "2.2 Define Pydantic models (Recipe, IngredientItem, IngredientEntity, Pantry)", "estimate": "1-2h"},
            {"title": "2.3 Define DB schema and create Containers (Recipes, Pantry, IngredientsMasterList) with Partition Keys", "estimate": "1h"},
            {"title": "2.4 Implement CRUD functions for Recipes (Python SDK + Pydantic)", "estimate": "3-5h"},
            {"title": "2.5 Implement Get/Update Pantry functions (List of IDs) (Python SDK + Pydantic)", "estimate": "1-2h"}, # Simplified
            {"title": "2.6 Implement Get/Update IngredientEntity logic (incl. exact match/similarity check + HITL prompt + calorie cache)", "estimate": "3-6h"}, # Refined logic
            {"title": "2.7 Integrate credential retrieval from Key Vault via azure-identity", "estimate": "1h"},
        ]
    },
    # --- EPIC 3 ---
     {
        "title": "[EPIC] 3: Backend - AI Services Integration & Core Logic",
        "estimate": "49-96h", # Broad estimate
        "tasks": [
            # DI
            {"title": "3.1.1 [DI] Create/Configure AI Services/DI resource", "estimate": "0.5h"},
            {"title": "3.1.2 [DI] (Optional) Train/Deploy custom recipe model (*Excluding labeling*)", "estimate": "1-2h"},
            {"title": "3.1.3 [DI] Integrate DI SDK for recipe image analysis", "estimate": "2-4h"},
            {"title": "3.1.4 [DI] Connect DI output to Streamlit UI for HITL verification", "estimate": "1-2h"},
            # Lang
            {"title": "3.2.1 [Lang] Create/Configure AI Services/Language resource", "estimate": "0.5h"},
            {"title": "3.2.2 [Lang] (If Custom) Train/Deploy custom classification model (*Excluding labeling*)", "estimate": "1-2h"},
            {"title": "3.2.3 [Lang] Integrate Language SDK for classification (custom or zero-shot)", "estimate": "1.5-3h"},
            {"title": "3.2.4 [Lang] Integrate result+HITL into recipe saving", "estimate": "0.5-1h"},
             # Vision
            {"title": "3.3.1 [Vision] Create/Configure AI Services/Vision resource", "estimate": "0.5h"},
            {"title": "3.3.2 [Vision] Create/Configure Azure Blob Storage for dish images", "estimate": "0.5h"},
            {"title": "3.3.3 [Vision] Integrate Vision SDK (Analyze Image: Tags, Caption, Crop)", "estimate": "1.5-3h"},
            {"title": "3.3.4 [Vision] Logic for photo upload/save (Blob) and metadata (Cosmos)", "estimate": "0.5-1h"},
            # Speech
            {"title": "3.4.1 [Speech] Create/Configure AI Services/Speech resource", "estimate": "0.5h"},
            {"title": "3.4.2 [Speech] Implement TTS (Read Aloud) with SDK and st.audio", "estimate": "2-4h"},
            {"title": "3.4.3 [Speech] (If Live STT) Setup live audio input (streamlit-webrtc?)", "estimate": "2-4h"},
            {"title": "3.4.4 [Speech] Integrate STT SDK (streaming or file)", "estimate": "2-4h"},
            {"title": "3.4.5 [Speech] Connect STT output to UI + HITL", "estimate": "0.5-2h"},
            # OpenAI Direct
            {"title": "3.5.1 [OpenAI] Create Azure OpenAI resource and deploy GPT model", "estimate": "0.5-1h"},
            {"title": "3.5.2 [OpenAI] Integrate azure-openai SDK for direct call (Generate New Recipe)", "estimate": "1-2h"},
            {"title": "3.5.3 [OpenAI] Prompt engineering for new recipe generation", "estimate": "0.5-1h"},
            # SK Agent
            {"title": "3.6.1 [SK] Setup Semantic Kernel library", "estimate": "0.5-1h"},
            {"title": "3.6.2 [SK] Create custom SK Plugin for Cosmos DB query (Recipe Search Tool)", "estimate": "1.5-3h"},
            {"title": "3.6.3 [SK] Define prompt/function/plan for recipe suggestion agent", "estimate": "2-4h"},
            {"title": "3.6.4 [SK] Integrate SK agent invocation in Streamlit", "estimate": "1-2h"},
             # AI Search
            {"title": "3.7.1 [Search] Create Azure AI Search resource", "estimate": "0.5h"},
            {"title": "3.7.2 [Search] Define Index Schema", "estimate": "1-2h"},
            {"title": "3.7.3 [Search] Configure Data Source (Cosmos DB)", "estimate": "0.5-1h"},
            {"title": "3.7.4 [Search] (Optional) Create Skillset (e.g., Key Phrases)", "estimate": "1-3h"},
            {"title": "3.7.5 [Search] Create/Run Indexer", "estimate": "0.5-1h"},
            {"title": "3.7.6 [Search] Integrate Search SDK for query and facet", "estimate": "3-5h"},
             # Calorie Calc
            {"title": "3.8.1 [Calorie] Research/Choose Free Food DB API", "estimate": "1-2h"},
            {"title": "3.8.2 [Calorie] Implement External API Lookup Function", "estimate": "1.5-3h"},
            {"title": "3.8.3 [Calorie] Implement Calculation Logic (from structured input + cache + basic conversions)", "estimate": "1-2h"},
            {"title": "3.8.4 [Calorie] Handle Not Found Ingredients/Update cache in Master List", "estimate": "0.5-1h"}, # Added cache update
            # URL Import
            {"title": "3.9.1 [Import] Integrate recipe-scrapers", "estimate": "1.5-3h"},
            {"title": "3.9.2 [Import] Implement fallback text extraction", "estimate": "1-2h"},
            {"title": "3.9.3 [Import] Implement OpenAI call/prompt to structure fallback text", "estimate": "1-2h"},
            {"title": "3.9.4 [Import] Connect scraper/AI output to UI for HITL verification", "estimate": "1.5-3h"},
            # Shopping List
            {"title": "3.10.1 [Shopping] Implement set difference calculation + quantity aggregation", "estimate": "0.5-1.5h"},
            {"title": "3.10.2 [Shopping] Prepare output for UI (with 'Check stock!' warning) and download", "estimate": "0.5-1.5h"},
        ]
    },
    # --- EPIC 4 ---
    {
        "title": "[EPIC] 4: Frontend - Streamlit UI",
        "estimate": "18-40h", # Slightly increased for HITL complexity and ingredient management
        "tasks": [
            {"title": "4.1 General app structure (navigation, multi-page/sections)", "estimate": "2-4h"},
            {"title": "4.2 Recipe Detail View UI (text, img, categories, metadata, estimated calories)", "estimate": "2-4h"},
            {"title": "4.3 Browse/Filtering Cookbook UI (incl. categories/facet Search)", "estimate": "2-4h"},
            {"title": "4.4 Pantry Management UI (list of IDs, e.g., with multiselect)", "estimate": "1-3h"}, # Simplified
            {"title": "4.5 Add/Edit Recipe UI (Manual + Structured Fields Ing. + HITL for DI/Classification/URL Import)", "estimate": "4-7h"}, # More complex
            {"title": "4.6 IngredientEntity Master Management UI (CRUD with st.data_editor?)", "estimate": "4-8h"},
            {"title": "4.7 AI Input/Output UI (Dictation, Reading, Img Upload, Prompt Gen., URL Import)", "estimate": "2-4h"},
            {"title": "4.8 Advanced Search UI (Bar, Facet Filters, Results)", "estimate": "1.5-3h"},
            {"title": "4.9 Estimated Calories View UI and Shopping List Download Button", "estimate": "1-2h"},
            {"title": "4.10 General UX/UI improvements and mobile test/optimization", "estimate": "2-5h"},
        ]
    },
    # --- EPIC 5 ---
    {
        "title": "[EPIC] 5: Deployment & Final Testing",
        "estimate": "5-10h",
        "tasks": [
             {"title": "5.1 Create Dockerfile for Streamlit app", "estimate": "1-2h"},
             {"title": "5.2 Create and configure Azure App Service (or ACA) with Managed Identity", "estimate": "1-2h"},
             {"title": "5.3 Configure CI/CD pipeline (Optional)", "estimate": "1-3h"},
             {"title": "5.4 Configure Key Vault secrets and Managed Identity permissions in Azure deployment", "estimate": "0.5-1h"},
             {"title": "5.5 End-to-end testing and post-deployment debugging", "estimate": "2-4h"},
        ]
    },
]


# --- Helper Function to Create Issue ---
def create_github_issue(repo_id, title, body, labels=None):
    """Creates a GitHub issue using the GraphQL API."""
    if not GITHUB_PAT:
        print("ERROR: GITHUB_PAT not set.")
        return None

    # Note: The mutation may need adjustments if you want to pass label IDs, etc.
    # This base version only passes title and body.
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
        # If you want to add labels, you must pass an array of label Node IDs:
        # "labelIds": ["LABEL_NODE_ID_1", "LABEL_NODE_ID_2"]
    }
    headers = {
        "Authorization": f"bearer {GITHUB_PAT}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    payload = {"query": mutation, "variables": variables}

    # Add a simple retry in case of temporary API errors
    max_retries = 3
    for attempt in range(max_retries):
        try:
            response = requests.post(GITHUB_GRAPHQL_URL, headers=headers, json=payload, timeout=30) # Timeout added
            response.raise_for_status()
            response_data = response.json()

            if "errors" in response_data:
                print(f"GraphQL ERROR for '{title}' (Attempt {attempt+1}/{max_retries}): {response_data['errors']}")
                if attempt == max_retries - 1: return None # Failed after all retries
                time.sleep(2 ** attempt) # Exponential backoff
                continue # Retry

            elif "data" in response_data and response_data["data"].get("createIssue") and response_data["data"]["createIssue"].get("issue"):
                 return response_data["data"]["createIssue"]["issue"]
            else:
                print(f"Unexpected response for '{title}' (Attempt {attempt+1}/{max_retries}): {response_data}")
                if attempt == max_retries - 1: return None
                time.sleep(2 ** attempt)
                continue
        except requests.exceptions.Timeout:
             print(f"TIMEOUT for '{title}' (Attempt {attempt+1}/{max_retries})")
             if attempt == max_retries - 1: return None
             time.sleep(2 ** attempt) # Exponential backoff
        except requests.exceptions.RequestException as e:
            print(f"HTTP ERROR for '{title}' (Attempt {attempt+1}/{max_retries}): {e}")
            # It may not be worth retrying for all HTTP errors, but we do it for simplicity
            if attempt == max_retries - 1: return None
            time.sleep(2 ** attempt)
        except json.JSONDecodeError:
            print(f"JSON Decode ERROR for '{title}'. Response: {response.text}")
            return None # Do not retry for malformed JSON
    return None # Failed after all retries

# --- Main Logic ---
if __name__ == "__main__":
    print("--- Creating GitHub Issues for Mirai Cook ---")

    epic_issue_map = {} # Dictionary to map Epic title -> created Issue number

    # 1. Create Epics
    print("\n[PHASE 1] Creating EPIC Issues...")
    for epic_data in project_structure:
        epic_title = epic_data["title"]
        epic_body = f"**Total Epic Estimate:** {epic_data.get('estimate', 'N/A')}\n\n*(This is an Epic that groups the underlying tasks)*"
        print(f"  Creating Epic: {epic_title}...")
        created_epic = create_github_issue(REPOSITORY_ID, epic_title, epic_body)
        if created_epic:
            epic_issue_map[epic_title] = created_epic["number"]
            print(f"    -> Created: #{created_epic['number']} - {created_epic['url']}")
        else:
            print(f"    -> ERROR creating Epic '{epic_title}'.")
        time.sleep(1.5) # Slightly longer pause between issues

    # 2. Create child Tasks, referencing the Epics
    print("\n[PHASE 2] Creating CHILD TASK Issues...")
    for epic_data in project_structure:
        parent_epic_title = epic_data["title"]
        parent_issue_number = epic_issue_map.get(parent_epic_title)

        if not parent_issue_number:
            print(f"\n  WARNING: Unable to create tasks for Epic '{parent_epic_title}' because the Epic was not created or mapped.")
            continue

        print(f"\n  Creating Tasks for Epic #{parent_issue_number} - {parent_epic_title}...")
        for task_data in epic_data.get("tasks", []):
            task_title = task_data["title"]
            task_body = f"**Task Estimate:** {task_data.get('estimate', 'N/A')}\n\n"
            if "body" in task_data:
                 task_body += task_data["body"] + "\n\n"
            task_body += f"Parent Epic: #{parent_issue_number}"

            print(f"    Creating Task: {task_title}...")
            created_task = create_github_issue(REPOSITORY_ID, task_title, task_body)
            if created_task:
                 print(f"      -> Created: #{created_task['number']} - {created_task['url']}")
            else:
                 print(f"      -> ERROR creating Task '{task_title}'.")
            time.sleep(1.5) # Pause

    print("\n--- Issue Creation Completed ---")