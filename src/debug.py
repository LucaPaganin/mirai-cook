import os
import sys
from pathlib import Path
THISDIR = Path(__file__).parent.resolve()
sys.path.insert(0, str(THISDIR.parent))  # Adjust the path to your project structure

from src.azure_clients import _get_key_vault_client, _get_secrets_from_key_vault, _initialize_openai_client
from src.ai_services.genai import SYSTEM_PROMPT_INGREDIENTS_SPLITTER, parse_openai_response
import os
from src.test_data import test_ingredients

if __name__ == "__main__":
    kvc = _get_key_vault_client()
    secrets = _get_secrets_from_key_vault(kvc, ["AzureOpenAIEndpoint", "AzureOpenAIKey"])
    openai_client = _initialize_openai_client(secrets)

    ingredient_list = [ti['text'] for ti in test_ingredients]  # Limitiamo a 10 ingredienti per il test
        
    user_prompt = "Process the following list of ingredients:\n" + "\n".join(ingredient_list)
    
    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini", # Il nome del tuo deployment
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT_INGREDIENTS_SPLITTER},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0, # Usiamo 0 per risposte più deterministiche/fattuali
            max_tokens=4096 # Imposta un limite massimo ragionevole per i token di risposta
        )

        # --- Stampa della Risposta ---
        if response.choices:
            extracted_data = response.choices[0].message.content
            print("\n--- Risposta dal Modello ---")
            print(extracted_data)
            print("---------------------------\n")
            
            # Stampa informazioni sull'utilizzo (opzionale)
            if response.usage:
                print(f"Token Prompt: {response.usage.prompt_tokens}")
                print(f"Token Completamento: {response.usage.completion_tokens}")
                print(f"Token Totali: {response.usage.total_tokens}")
            
            results = parse_openai_response(response)
            print("\n--- Risultati Estratti ---")
            print(len(results), "ingredienti trovati.")
            for res, expected in zip(results, [ti["expected"] for ti in test_ingredients]):
                try:
                    del expected["original"]
                    expected["quantity"] = float(expected["quantity"])
                except ValueError:
                    pass  # Mantieni la stringa originale se non è convertibile a float
                if res != expected:
                    print(f"Errore: {res} != {expected}")
        else:
            print("Nessuna risposta ricevuta dal modello.")

    except Exception as e:
        print(f"Errore durante la chiamata all'API di Azure OpenAI: {e}")