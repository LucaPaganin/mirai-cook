test_ingredients = [
        {
            "text": "Farina 00 100 g",
            "expected": {
                "name": "Farina 00",
                "quantity": 100,
                "unit": "g",
                "notes": "N/A",
                "original": "Farina 00 100 g"
            }
        },
        {
            "text": "Riso Carnaroli, 350 g",
            "expected": {
                "name": "Riso Carnaroli",
                "quantity": 350,
                "unit": "g",
                "notes": "N/A",
                "original": "Riso Carnaroli, 350 g"
            }
        },
        {
            "text": "Speck tagliato grosso, 100 g",
            "expected": {
                "name": "Speck",
                "quantity": 100,
                "unit": "g",
                "notes": "tagliato grosso",
                "original": "Speck tagliato grosso, 100 g"
            }
        },
        {
            "text": "Ricotta fresca, 60 g",
            "expected": {
                "name": "Ricotta fresca",
                "quantity": 60,
                "unit": "g",
                "notes": "N/A",
                "original": "Ricotta fresca, 60 g"
            }
        },
        {
            "text": "Gherigli di noce, 50 g",
            "expected": {
                "name": "Gherigli di noce",
                "quantity": 50,
                "unit": "g",
                "notes": "N/A",
                "original": "Gherigli di noce, 50 g"
            }
        },
        {
            "text": "Lattuga, 1 cespo",
            "expected": {
                "name": "Lattuga",
                "quantity": 1,
                "unit": "cespo",
                "notes": "N/A",
                "original": "Lattuga, 1 cespo"
            }
        },
        {
            "text": "Cipolla, 1",
            "expected": {
                "name": "Cipolla",
                "quantity": 1,
                "unit": "N/A",
                "notes": "N/A",
                "original": "Cipolla, 1"
            }
        },
        {
            "text": "Aglio, 1 spicchio",
            "expected": {
                "name": "Aglio",
                "quantity": 1,
                "unit": "spicchio",
                "notes": "N/A",
                "original": "Aglio, 1 spicchio"
            }
        },
        {
            "text": "Parmigiano grattugiato",
            "expected": {
                "name": "Parmigiano",
                "quantity": "N/A",
                "unit": "N/A",
                "notes": "grattugiato",
                "original": "Parmigiano grattugiato"
            }
        },
        {
            "text": "Burro, 50 g",
            "expected": {
                "name": "Burro",
                "quantity": 50,
                "unit": "g",
                "notes": "N/A",
                "original": "Burro, 50 g"
            }
        },
        {
            "text": "Vino bianco secco, 1/2 bicchiere",
            "expected": {
                "name": "Vino bianco secco",
                "quantity": 0.5,
                "unit": "bicchiere",
                "notes": "N/A",
                "original": "Vino bianco secco, 1/2 bicchiere"
            }
        },
        {
            "text": "Brodo vegetale, 8 dl scarsi",
            "expected": {
                "name": "Brodo vegetale",
                "quantity": 8,
                "unit": "dl",
                "notes": "scarsi",
                "original": "Brodo vegetale, 8 dl scarsi"
            }
        },
        {
            "text": "Prezzemolo, qualche foglia",
            "expected": {
                "name": "Prezzemolo",
                "quantity": "N/A",
                "unit": "foglia",
                "notes": "qualche",
                "original": "Prezzemolo, qualche foglia"
            }
        },
        {
            "text": "Olio extravergine d'oliva",
            "expected": {
                "name": "Olio extravergine d'oliva",
                "quantity": "N/A",
                "unit": "N/A",
                "notes": "N/A",
                "original": "Olio extravergine d'oliva"
            }
        },
        {
            "text": "Sale, pepe",
            "expected": {
                "name": "Sale, pepe",
                "quantity": "N/A",
                "unit": "N/A",
                "notes": "N/A",
                "original": "Sale, pepe"
            }
        },
        {
            "text": "100g burro, ammorbidito",
            "expected": {
                "name": "burro",
                "quantity": 100,
                "unit": "g",
                "notes": "ammorbidito",
                "original": "100g burro, ammorbidito"
            }
        },
        {
            "text": "g 100 farina",
            "expected": {
                "name": "farina",
                "quantity": 100,
                "unit": "g",
                "notes": "N/A",
                "original": "g 100 farina"
            }
        },
        {
            "text": "Cipolle dorate 1,5 kg",
            "expected": {
                "name": "Cipolle dorate",
                "quantity": 1.5,
                "unit": "kg",
                "notes": "N/A",
                "original": "Cipolle dorate 1,5 kg"
            }
        },
        {
            "text": "2 tazze di farina 00, setacciata",
            "expected": {
                "name": "farina 00",
                "quantity": 2,
                "unit": "tazze",
                "notes": "setacciata",
                "original": "2 tazze di farina 00, setacciata"
            }
        },
        {
            "text": "1 1/2 cucchiaino di bicarbonato di sodio",
            "expected": {
                "name": "bicarbonato di sodio",
                "quantity": 1.5,
                "unit": "cucchiaino",
                "notes": "N/A",
                "original": "1 1/2 cucchiaino di bicarbonato di sodio"
            }
        },
        {
            "text": "1/2 tazza di zucchero semolato",
            "expected": {
                "name": "zucchero semolato",
                "quantity": 0.5,
                "unit": "tazza",
                "notes": "N/A",
                "original": "1/2 tazza di zucchero semolato"
            }
        },
        {
            "text": "2 uova grandi",
            "expected": {
                "name": "uova",
                "quantity": 2,
                "unit": "N/A",
                "notes": "grandi",
                "original": "2 uova grandi"
            }
        },
        {
            "text": "1 limone (scorza e succo)",
            "expected": {
                "name": "limone",
                "quantity": 1,
                "unit": "N/A",
                "notes": "scorza e succo",
                "original": "1 limone (scorza e succo)"
            }
        },
        {
            "text": "Sale q.b.",
            "expected": {
                "name": "Sale",
                "quantity": "N/A",
                "unit": "N/A",
                "notes": "q.b.",
                "original": "Sale q.b."
            }
        },
        {
            "text": "Un pizzico di noce moscata",
            "expected": {
                "name": "noce moscata",
                "quantity": "N/A",
                "unit": "pizzico",
                "notes": "N/A",
                "original": "Un pizzico di noce moscata"
            }
        },
        {
            "text": "1 kg patate",
            "expected": {
                "name": "patate",
                "quantity": 1,
                "unit": "kg",
                "notes": "N/A",
                "original": "1 kg patate"
            }
        },
        {
            "text": "1,5 litri d'acqua",
            "expected": {
                "name": "acqua",
                "quantity": 1.5,
                "unit": "litri",
                "notes": "N/A",
                "original": "1,5 litri d'acqua"
            }
        },
        {
            "text": "1/4 lb carne macinata di manzo",
            "expected": {
                "name": "carne macinata di manzo",
                "quantity": 0.25,
                "unit": "lb",
                "notes": "N/A",
                "original": "1/4 lb carne macinata di manzo"
            }
        },
        {
            "text": "1 lattina (14,5 oz) di pomodori a cubetti",
            "expected": {
                "name": "pomodori a cubetti",
                "quantity": 1,
                "unit": "lattina",
                "notes": "14,5 oz",
                "original": "1 lattina (14,5 oz) di pomodori a cubetti"
            }
        },
        {
            "text": "3 spicchi d'aglio, tritati",
            "expected": {
                "name": "aglio",
                "quantity": 3,
                "unit": "spicchi",
                "notes": "tritati",
                "original": "3 spicchi d'aglio, tritati"
            }
        },
        {
            "text": "1/2 etto prosciutto cotto",
            "expected": {
                "name": "prosciutto cotto",
                "quantity": 0.5,
                "unit": "etto",
                "notes": "N/A",
                "original": "1/2 etto prosciutto cotto"
            }
        },
        {
            "text": "Sale",
            "expected": {
                "name": "Sale",
                "quantity": "N/A",
                "unit": "N/A",
                "notes": "N/A",
                "original": "Sale"
            }
        },
        {
            "text": "pepe",
            "expected": {
                "name": "pepe",
                "quantity": "N/A",
                "unit": "N/A",
                "notes": "N/A",
                "original": "pepe"
            }
        },
        {
            "text": "Brodo vegetale",
            "expected": {
                "name": "Brodo vegetale",
                "quantity": "N/A",
                "unit": "N/A",
                "notes": "N/A",
                "original": "Brodo vegetale"
            }
        },
        {
            "text": "2 mele",
            "expected": {
                "name": "mele",
                "quantity": 2,
                "unit": "N/A",
                "notes": "N/A",
                "original": "2 mele"
            }
        },
        {
            "text": "100 farina 00",
            "expected": {
                "name": "farina 00",
                "quantity": 100,
                "unit": "N/A",
                "notes": "N/A",
                "original": "100 farina 00"
            }
        },
        {
            "text": "Farina 100 g",
            "expected": {
                "name": "Farina",
                "quantity": 100,
                "unit": "g",
                "notes": "N/A",
                "original": "Farina 100 g"
            }
        },
        {
            "text": "Uova 2 grandi",
            "expected": {
                "name": "Uova",
                "quantity": 2,
                "unit": "N/A",
                "notes": "grandi",
                "original": "Uova 2 grandi"
            }
        },
        {
            "text": "Olio d'oliva 2 cucchiai",
            "expected": {
                "name": "Olio d'oliva",
                "quantity": 2,
                "unit": "cucchiai",
                "notes": "N/A",
                "original": "Olio d'oliva 2 cucchiai"
            }
        },
        {
            "text": "Basilico 1 mazzetto",
            "expected": {
                "name": "Basilico",
                "quantity": 1,
                "unit": "mazzetto",
                "notes": "N/A",
                "original": "Basilico 1 mazzetto"
            }
        },
        {
            "text": "1 CUCCHIAINO Sale",
            "expected": {
                "name": "Sale",
                "quantity": 1,
                "unit": "CUCCHIAINO",
                "notes": "N/A",
                "original": "1 CUCCHIAINO Sale"
            }
        }
    ]