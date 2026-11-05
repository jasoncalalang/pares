#!/usr/bin/env bash
# Downloads the two USDA FoodData Central CSV sets into data/ and unzips them
# as usda.py expects (data/sr and data/fnd). Safe to rerun. data/ is gitignored.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p data/sr data/fnd
base=https://fdc.nal.usda.gov/fdc-datasets
sr=FoodData_Central_sr_legacy_food_csv_2018-04
fnd=FoodData_Central_foundation_food_csv_2025-04-24
[ -f "data/$sr.zip" ] || curl -fL --retry 3 -o "data/$sr.zip" "$base/$sr.zip"
[ -f "data/$fnd.zip" ] || curl -fL --retry 3 -o "data/$fnd.zip" "$base/$fnd.zip"
unzip -qo "data/$sr.zip" -d data/sr
unzip -qo "data/$fnd.zip" -d data/fnd
rm -f data/usda-index.json
echo "USDA data ready in $(pwd)/data. Try: python3 -I usda.py search rice"
