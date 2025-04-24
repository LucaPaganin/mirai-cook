import os
import sys
from pathlib import Path
THISDIR = Path(__file__).parent.resolve()
sys.path.insert(0, str(THISDIR.parent))  # Adjust the path to your project structure

from src.ai_services.language import parse_single_ingredient_ner
from src.azure_clients import _get_key_vault_client, _get_secrets_from_key_vault, _initialize_language_client
import os
import pickle

if __name__ == "__main__":
    # Example usage of the parse_single_ingredient_ner function
    test_ingredients = [
        {
            "text": "Farina 00 100 g",
            "expected": {
                "name": "Farina 00",
                "quantity": 100,
                "unit": "g",
                "notes": None
            }
        },
        {
            "text": "Riso Carnaroli, 350 g",
            "expected": {
                "name": "Riso Carnaroli",
                "quantity": 350,
                "unit": "g",
                "notes": None
            }
        },
        {
            "text": "Speck tagliato grosso, 100 g",
            "expected": {
                "name": "Speck",
                "quantity": 100,
                "unit": "g",
                "notes": "tagliato grosso"
            }
        },
        {
            "text": "Ricotta fresca, 60 g",
            "expected": {
                "name": "Ricotta fresca",
                "quantity": 60,
                "unit": "g",
                "notes": None
            }
        },
        {
            "text": "Gherigli di noce, 50 g",
            "expected": {
                "name": "Gherigli di noce",
                "quantity": 50,
                "unit": "g",
                "notes": None
            }
        },
        {
            "text": "Lattuga, 1 cespo",
            "expected": {
                "name": "Lattuga",
                "quantity": 1,
                "unit": "cespo",
                "notes": None
            }
        },
        {
            "text": "Cipolla, 1",
            "expected": {
                "name": "Cipolla",
                "quantity": 1,
                "unit": None,
                "notes": None
            }
        },
        {
            "text": "Aglio, 1 spicchio",
            "expected": {
                "name": "Aglio",
                "quantity": 1,
                "unit": "spicchio",
                "notes": None
            }
        },
        {
            "text": "Parmigiano grattugiato",
            "expected": {
                "name": "Parmigiano",
                "quantity": None,
                "unit": None,
                "notes": "grattugiato"
            }
        },
        {
            "text": "Burro, 50 g",
            "expected": {
                "name": "Burro",
                "quantity": 50,
                "unit": "g",
                "notes": None
            }
        },
        {
            "text": "Vino bianco secco, 1/2 bicchiere",
            "expected": {
                "name": "Vino bianco secco",
                "quantity": 0.5,
                "unit": "bicchiere",
                "notes": None
            }
        },
        {
            "text": "Brodo vegetale, 8 dl scarsi",
            "expected": {
                "name": "Brodo vegetale",
                "quantity": 8,
                "unit": "dl",
                "notes": "scarsi"
            }
        },
        {
            "text": "Prezzemolo, qualche foglia",
            "expected": {
                "name": "Prezzemolo",
                "quantity": None,
                "unit": "foglia",
                "notes": "qualche"
            }
        },
        {
            "text": "Olio extravergine d'oliva",
            "expected": {
                "name": "Olio extravergine d'oliva",
                "quantity": None,
                "unit": None,
                "notes": None
            }
        },
        {
            "text": "Sale, pepe",
            "expected": {
                "name": "Sale, pepe",
                "quantity": None,
                "unit": None,
                "notes": None
            }
        },
        {
            "text": "100g burro, ammorbidito",
            "expected": {
                "name": "burro",
                "quantity": 100,
                "unit": "g",
                "notes": "ammorbidito"
            }
        },
        {
            "text": "g 100 farina",
            "expected": {
                "name": "farina",
                "quantity": 100,
                "unit": "g",
                "notes": None
            }
        },
        {
            "text": "Cipolle dorate 1,5 kg",
            "expected": {
                "name": "Cipolle dorate",
                "quantity": 1.5,
                "unit": "kg",
                "notes": None
            }
        },
        {
            "text": "2 tazze di farina 00, setacciata",
            "expected": {
                "name": "farina 00",
                "quantity": 2,
                "unit": "tazze",
                "notes": "setacciata"
            }
        },
        {
            "text": "1 1/2 cucchiaino di bicarbonato di sodio",
            "expected": {
                "name": "bicarbonato di sodio",
                "quantity": 1.5,
                "unit": "cucchiaino",
                "notes": None
            }
        },
        {
            "text": "1/2 tazza di zucchero semolato",
            "expected": {
                "name": "zucchero semolato",
                "quantity": 0.5,
                "unit": "tazza",
                "notes": None
            }
        },
        {
            "text": "2 uova grandi",
            "expected": {
                "name": "uova",
                "quantity": 2,
                "unit": None,
                "notes": "grandi"
            }
        },
        {
            "text": "1 limone (scorza e succo)",
            "expected": {
                "name": "limone",
                "quantity": 1,
                "unit": None,
                "notes": "scorza e succo"
            }
        },
        {
            "text": "Sale q.b.",
            "expected": {
                "name": "Sale",
                "quantity": None,
                "unit": None,
                "notes": "q.b."
            }
        },
        {
            "text": "Un pizzico di noce moscata",
            "expected": {
                "name": "noce moscata",
                "quantity": None,
                "unit": "pizzico",
                "notes": None
            }
        },
        {
            "text": "1 kg patate",
            "expected": {
                "name": "patate",
                "quantity": 1,
                "unit": "kg",
                "notes": None
            }
        },
        {
            "text": "1,5 litri d'acqua",
            "expected": {
                "name": "acqua",
                "quantity": 1.5,
                "unit": "litri",
                "notes": None
            }
        },
        {
            "text": "1/4 lb carne macinata di manzo",
            "expected": {
                "name": "carne macinata di manzo",
                "quantity": 0.25,
                "unit": "lb",
                "notes": None
            }
        },
        {
            "text": "1 lattina (14,5 oz) di pomodori a cubetti",
            "expected": {
                "name": "pomodori a cubetti",
                "quantity": 1,
                "unit": "lattina",
                "notes": "14,5 oz"
            }
        },
        {
            "text": "3 spicchi d'aglio, tritati",
            "expected": {
                "name": "aglio",
                "quantity": 3,
                "unit": "spicchi",
                "notes": "tritati"
            }
        },
        {
            "text": "1/2 etto prosciutto cotto",
            "expected": {
                "name": "prosciutto cotto",
                "quantity": 0.5,
                "unit": "etto",
                "notes": None
            }
        },
        {
            "text": "Sale e pepe",
            "expected": {
                "name": "Sale e pepe",
                "quantity": None,
                "unit": None,
                "notes": None
            }
        },
        {
            "text": "Brodo vegetale",
            "expected": {
                "name": "Brodo vegetale",
                "quantity": None,
                "unit": None,
                "notes": None
            }
        },
        {
            "text": "2 mele",
            "expected": {
                "name": "mele",
                "quantity": 2,
                "unit": None,
                "notes": None
            }
        },
        {
            "text": "100 farina 00",
            "expected": {
                "name": "farina 00",
                "quantity": 100,
                "unit": None,
                "notes": None
            }
        },
        {
            "text": "Farina 100 g",
            "expected": {
                "name": "Farina",
                "quantity": 100,
                "unit": "g",
                "notes": None
            }
        },
        {
            "text": "Uova 2 grandi",
            "expected": {
                "name": "Uova",
                "quantity": 2,
                "unit": None,
                "notes": "grandi"
            }
        },
        {
            "text": "Olio d'oliva 2 cucchiai",
            "expected": {
                "name": "Olio d'oliva",
                "quantity": 2,
                "unit": "cucchiai",
                "notes": None
            }
        },
        {
            "text": "Basilico 1 mazzetto",
            "expected": {
                "name": "Basilico",
                "quantity": 1,
                "unit": "mazzetto",
                "notes": None
            }
        },
        {
            "text": "1 CUCCHIAINO Sale",
            "expected": {
                "name": "Sale",
                "quantity": 1,
                "unit": "CUCCHIAINO",
                "notes": None
            }
        }
    ]

    pickle_path = "language_client.pkl"

    if os.path.exists(pickle_path):
        with open(pickle_path, "rb") as f:
            language_client = pickle.load(f)
    else:
        kvc = _get_key_vault_client()
        secrets = _get_secrets_from_key_vault(kvc, ["LanguageServiceKey", "LanguageServiceEndpoint"])
        language_client = _initialize_language_client(secrets)
        with open(pickle_path, "wb") as f:
            pickle.dump(language_client, f)
    
    
    for test_line in test_ingredients:
        print(f"Testing line: {test_line}")
        result = parse_single_ingredient_ner(language_client, test_line)
        print(f"Parsed result: {result}")