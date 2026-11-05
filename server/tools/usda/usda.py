"""Look up USDA FoodData Central values from the local CSV downloads.

usage: python3 -I usda.py search <words...>   foods whose description has every word
       python3 -I usda.py show <fdcId>        kcal per 100 g and household portions
Data: SR Legacy 2018-04 and Foundation Foods 2025-04-24, downloaded by fetch.sh
into data/ next to this file (gitignored). Energy = nutrient 1008 (kcal); Foundation foods without
1008 use 2048 (Atwater specific) then 2047 (Atwater general), and say so.
"""
import csv, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
DL = os.path.join(HERE, 'data')
SETS = {'SR Legacy 2018-04': os.path.join(DL, 'sr', 'FoodData_Central_sr_legacy_food_csv_2018-04'),
        'Foundation 2025-04-24': os.path.join(DL, 'fnd', 'FoodData_Central_foundation_food_csv_2025-04-24')}
INDEX = os.path.join(DL, 'usda-index.json')

def build():
    foods = {}
    for name, d in SETS.items():
        keep = set()
        for r in csv.DictReader(open(os.path.join(d, 'food.csv'), encoding='utf-8')):
            if r['data_type'] in ('sr_legacy_food', 'foundation_food'):
                foods[r['fdc_id']] = {'set': name, 'description': r['description'], 'energy': {}, 'portions': []}
                keep.add(r['fdc_id'])
        for r in csv.DictReader(open(os.path.join(d, 'food_nutrient.csv'), encoding='utf-8')):
            if r['fdc_id'] in keep and r['nutrient_id'] in ('1008', '2047', '2048') and r['amount']:
                foods[r['fdc_id']]['energy'][r['nutrient_id']] = float(r['amount'])
        units = {r['id']: r['name'] for r in csv.DictReader(open(os.path.join(d, 'measure_unit.csv'), encoding='utf-8'))}
        for r in csv.DictReader(open(os.path.join(d, 'food_portion.csv'), encoding='utf-8')):
            if r['fdc_id'] in keep and r['gram_weight']:
                u = units.get(r['measure_unit_id'], '')
                label = ' '.join(x for x in [r['amount'], '' if u == 'undetermined' else u, r['portion_description'], r['modifier']] if x).strip()
                foods[r['fdc_id']]['portions'].append([label, float(r['gram_weight'])])
    json.dump(foods, open(INDEX, 'w'))
    return foods

def load():
    return json.load(open(INDEX)) if os.path.exists(INDEX) else build()

def kcal(f):
    e = f['energy']
    for k, why in (('1008', 'Energy'), ('2048', 'Atwater specific'), ('2047', 'Atwater general')):
        if k in e:
            return e[k], why
    return None, 'no energy value'

foods = load()
cmd, args = sys.argv[1], sys.argv[2:]
if cmd == 'search':
    words = [w.lower() for w in args]
    hits = [(i, f) for i, f in foods.items() if all(w in f['description'].lower() for w in words)]
    for i, f in sorted(hits, key=lambda x: len(x[1]['description']))[:40]:
        k, why = kcal(f)
        print(f"{i:>7}  {k if k is not None else '-':>6} kcal/100g  [{f['set']}]  {f['description']}")
    print(f"({len(hits)} matches)")
elif cmd == 'show':
    f = foods[args[0]]
    k, why = kcal(f)
    print(f"fdcId {args[0]} [{f['set']}] {f['description']}\nkcal per 100 g: {k} ({why})")
    for label, g in f['portions']:
        print(f"  portion: {label} = {g} g")
