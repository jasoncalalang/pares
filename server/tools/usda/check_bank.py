"""Check a meal bank against the local USDA data. usage: python3 -I check_bank.py <meal-bank.json>

Every ingredient needs:
  kcalPer100g  equal to USDA's energy for usda.fdcId
  gramsPerUnit 1 for unit g; for pc the grams of portion.label; for ml portion.grams / portion.ml
  usda         {fdcId, description (exactly USDA's), match: exact|closest, note (required when closest)}
  portion      {label, grams[, ml]} for pc and ml units; label must be one of USDA's portions for that food
  edible       optional {fraction 0<f<1, note}; omit when the whole amount is eaten
Every meal: kcal == round_half_up(sum(qty * gramsPerUnit * edible.fraction * kcalPer100g / 100)).
Prints one line per problem (a missing or non-numeric field is a problem, not a crash), a per-meal
kcal table, and OK or FAIL last. Exits 0 on OK and 1 on FAIL.
"""
import json, os, re, sys
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
HERE = os.path.dirname(os.path.abspath(__file__))
INDEX = os.path.join(HERE, 'data', 'usda-index.json')
if not os.path.exists(INDEX):
    sys.exit('No USDA index yet. Run fetch.sh, then any usda.py command (e.g. usda.py search rice) builds it.')
idx = json.load(open(INDEX))
bank = json.load(open(sys.argv[1]))
ML = {'tbsp': Decimal('14.787'), 'tsp': Decimal('4.929'), 'cup': Decimal('236.588'), 'fl oz': Decimal('29.574')}
BANDS = {'breakfast': (300, 850), 'lunch': (350, 950), 'dinner': (350, 950), 'snack': (80, 450)}
bad = []
def D(x):
    # None for a missing, null or non-numeric value, so the caller records a PROBLEM instead of crashing.
    if x is None or isinstance(x, bool): return None
    try: v = Decimal(str(x))
    except InvalidOperation: return None
    return v if v.is_finite() else None
def kcal_of(f):
    for k in ('1008', '2048', '2047'):
        if k in f['energy']: return D(f['energy'][k])
per_unit = {}
for iid, ing in bank['ingredients'].items():
    u = ing.get('usda') or {}
    f = idx.get(str(u.get('fdcId')))
    if not f: bad.append(f'{iid}: usda.fdcId {u.get("fdcId")} not in SR Legacy or Foundation'); continue
    if u.get('description') != f['description']: bad.append(f'{iid}: usda.description should be exactly "{f["description"]}"')
    if u.get('match') not in ('exact', 'closest'): bad.append(f'{iid}: usda.match must be exact or closest')
    if u.get('match') == 'closest' and not u.get('note'): bad.append(f'{iid}: a closest match needs usda.note saying what differs')
    k = kcal_of(f)
    usable = True
    kp = D(ing.get('kcalPer100g'))
    if kp is None: bad.append(f'{iid}: kcalPer100g is missing or not a number'); usable = False
    elif k is None or kp != k: bad.append(f'{iid}: kcalPer100g {ing.get("kcalPer100g")} but USDA {f["description"]} says {k}')
    unit, gpu = ing.get('unit'), D(ing.get('gramsPerUnit'))
    if gpu is None: bad.append(f'{iid}: gramsPerUnit is missing or not a number'); usable = False
    if unit == 'g':
        if gpu is not None and gpu != 1: bad.append(f'{iid}: unit g needs gramsPerUnit 1')
    elif unit in ('pc', 'ml'):
        p = ing.get('portion') or {}
        match = [g for (lab, g) in f['portions'] if lab == p.get('label')]
        pg = D(p.get('grams'))
        if not match: bad.append(f'{iid}: portion.label "{p.get("label")}" is not a USDA portion of {u.get("fdcId")}; run usda.py show {u.get("fdcId")}')
        elif pg is None: bad.append(f'{iid}: portion.grams is missing or not a number')
        elif pg != D(match[0]): bad.append(f'{iid}: portion.grams should be {match[0]}')
        elif gpu is None: pass
        elif unit == 'pc' and gpu != D(match[0]): bad.append(f'{iid}: gramsPerUnit should be {match[0]} (one piece)')
        elif unit == 'ml':
            m = re.match(r'^(\d+(?:\.\d+)?) (tbsp|tsp|cup|fl oz)\b', p.get('label', ''))
            if not m: bad.append(f'{iid}: pick a tbsp, tsp, cup or fl oz portion for an ml ingredient')
            else:
                ml = D(m.group(1)) * ML[m.group(2)]
                pml = D(p.get('ml'))
                if pml is None or pml.quantize(Decimal('0.001')) != ml.quantize(Decimal('0.001')): bad.append(f'{iid}: portion.ml should be {ml.quantize(Decimal("0.001"))}')
                want = (D(match[0]) / ml).quantize(Decimal('0.001'), ROUND_HALF_UP)
                if gpu != want: bad.append(f'{iid}: gramsPerUnit should be {want} g per ml')
    else: bad.append(f'{iid}: unknown unit {unit}'); usable = False
    e = ing.get('edible')
    ef = Decimal(1)
    if e is not None:
        ef = D(e.get('fraction'))
        if ef is None or not (0 < ef < 1) or not e.get('note'):
            bad.append(f'{iid}: edible needs 0 < fraction < 1 and a note')
            if ef is None: usable = False
    if usable and k is not None: per_unit[iid] = gpu * ef * k / 100
rows = []
for m in bank['meals']:
    try: total = sum(D(r['qty']) * per_unit[r['id']] for r in m['ingredients'])
    except KeyError as ex: bad.append(f'{m["id"]}: ingredient {ex} has no usable kcal'); continue
    except TypeError: bad.append(f'{m["id"]}: an ingredient qty is missing or not a number'); continue
    want = int(total.quantize(Decimal(1), ROUND_HALF_UP))
    if m['kcal'] != want: bad.append(f'{m["id"]}: kcal {m["kcal"]} but its ingredients add to {want} ({total:.2f})')
    for s in m['slots']:
        lo, hi = BANDS[s]
        if not lo <= want <= hi: bad.append(f'{m["id"]}: {want} kcal is outside the {s} band {lo}-{hi}; check the amounts')
    rows.append(f'  {m["id"]:<22} {"/".join(m["slots"]):<22} {want:>5} kcal  P{m["pricePhp"]}')
for b in bad: print('PROBLEM', b)
print('\n'.join(rows))
print(f'{len(bank["ingredients"])} ingredients, {len(bank["meals"])} meals')
print('FAIL' if bad else 'OK')
sys.exit(1 if bad else 0)
