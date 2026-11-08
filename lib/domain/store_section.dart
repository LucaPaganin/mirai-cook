/// Store sections, in display order (SHOP-13).
enum StoreSection { produce, meatFish, dairy, pantry, frozen, other }

/// Assigns a store section to a normalized ingredient name (SHOP-14), with
/// user overrides taking precedence (SHOP-15).
class SectionResolver {
  SectionResolver({
    this.overrides = const {},
    this.seed = defaultSectionSeed,
  });

  final Map<String, StoreSection> overrides;
  final Map<String, StoreSection> seed;

  StoreSection resolve(String normalizedName) {
    final name = normalizedName;
    final override = overrides[name];
    if (override != null) return override;
    if (name.contains('surgelat')) return StoreSection.frozen;

    final exact = seed[name];
    if (exact != null) return exact;

    String? best;
    for (final key in seed.keys) {
      if (name.startsWith('$key ') && (best == null || key.length > best.length)) {
        best = key;
      }
    }
    if (best != null) return seed[best]!;

    final padded = ' $name ';
    for (final key in seed.keys) {
      if (padded.contains(' $key ') &&
          (best == null || key.length > best.length)) {
        best = key;
      }
    }
    return best == null ? StoreSection.other : seed[best]!;
  }
}

const _p = StoreSection.produce;
const _m = StoreSection.meatFish;
const _d = StoreSection.dairy;
const _s = StoreSection.pantry;
const _f = StoreSection.frozen;

/// Seed table of common Italian ingredients (normalized names).
const defaultSectionSeed = <String, StoreSection>{
  // Frutta e verdura
  'aglio': _p, 'cipolla': _p, 'cipolle': _p, 'cipollotto': _p,
  'scalogno': _p, 'carota': _p, 'carote': _p, 'sedano': _p,
  'patata': _p, 'patate': _p, 'pomodoro': _p, 'pomodori': _p,
  'pomodorini': _p, 'zucchina': _p, 'zucchine': _p, 'melanzana': _p,
  'melanzane': _p, 'peperone': _p, 'peperoni': _p, 'spinaci': _p,
  'insalata': _p, 'lattuga': _p, 'rucola': _p, 'radicchio': _p,
  'cavolfiore': _p, 'cavolo': _p, 'broccoli': _p, 'finocchio': _p,
  'finocchi': _p, 'funghi': _p, 'porri': _p, 'porro': _p, 'zucca': _p,
  'carciofi': _p, 'asparagi': _p, 'piselli': _p, 'fagiolini': _p,
  'basilico': _p, 'prezzemolo': _p, 'rosmarino': _p, 'salvia': _p,
  'timo': _p, 'menta': _p, 'limone': _p, 'limoni': _p, 'arancia': _p,
  'arance': _p, 'mela': _p, 'mele': _p, 'pera': _p, 'pere': _p,
  'banana': _p, 'banane': _p, 'fragole': _p, 'uva': _p, 'zenzero': _p,
  'avocado': _p, 'cetriolo': _p, 'cetrioli': _p,
  // Carne e pesce
  'pollo': _m, 'tacchino': _m, 'manzo': _m, 'vitello': _m, 'maiale': _m,
  'carne macinata': _m, 'macinato': _m, 'salsiccia': _m, 'salsicce': _m,
  'pancetta': _m, 'guanciale': _m, 'prosciutto': _m, 'prosciutto cotto': _m,
  'prosciutto crudo': _m, 'speck': _m, 'bresaola': _m, 'salame': _m,
  'agnello': _m, 'coniglio': _m, 'salmone': _m, 'tonno fresco': _m,
  'merluzzo': _m, 'baccala': _m, 'gamberi': _m, 'cozze': _m,
  'vongole': _m, 'calamari': _m, 'polpo': _m, 'orata': _m,
  'branzino': _m, 'alici': _m, 'acciughe': _m, 'spigola': _m,
  // Latticini
  'latte': _d, 'burro': _d, 'panna': _d, 'yogurt': _d, 'uova': _d,
  'uovo': _d, 'tuorli': _d, 'tuorlo': _d, 'albumi': _d, 'parmigiano': _d,
  'parmigiano reggiano': _d, 'grana': _d, 'grana padano': _d,
  'pecorino': _d, 'mozzarella': _d, 'ricotta': _d, 'mascarpone': _d,
  'gorgonzola': _d, 'stracchino': _d, 'scamorza': _d, 'provola': _d,
  'fontina': _d, 'formaggio': _d, 'besciamella': _d, 'burrata': _d,
  // Dispensa
  'farina': _s, 'zucchero': _s, 'sale': _s, 'pepe': _s, 'olio': _s,
  'aceto': _s, 'pasta': _s, 'spaghetti': _s, 'penne': _s, 'rigatoni': _s,
  'fusilli': _s, 'linguine': _s, 'tagliatelle': _s, 'lasagne': _s,
  'riso': _s, 'pane': _s, 'pangrattato': _s, 'lievito': _s,
  'pomodori pelati': _s, 'passata': _s, 'passata di pomodoro': _s,
  'polpa di pomodoro': _s, 'concentrato di pomodoro': _s, 'tonno': _s,
  'legumi': _s, 'ceci': _s, 'lenticchie': _s, 'fagioli': _s, 'brodo': _s,
  'dado': _s, 'vino': _s, 'vino bianco': _s, 'vino rosso': _s,
  'cacao': _s, 'cioccolato': _s, 'miele': _s, 'caffe': _s, 'noci': _s,
  'mandorle': _s, 'pinoli': _s, 'capperi': _s, 'olive': _s,
  'biscotti': _s, 'semola': _s, 'polenta': _s, 'couscous': _s,
  'noce moscata': _s, 'paprika': _s, 'curry': _s, 'origano': _s,
  'peperoncino': _s, 'cannella': _s, 'vaniglia': _s, 'amido di mais': _s,
  'maizena': _s, 'fecola di patate': _s, 'zucchero a velo': _s,
  // Surgelati
  'gelato': _f, 'spinaci surgelati': _f, 'piselli surgelati': _f,
};
