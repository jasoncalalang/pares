# USDA tools

Where the meal bank's calories come from. Every ingredient in
`src/main/resources/meal-bank.json` names a USDA FoodData Central food
(SR Legacy 2018-04 or Foundation 2025-04-24); these scripts look foods up and
check the bank against the same data. The owner chose USDA because FNRI's
PhilFCT site blocks automated access.

```sh
tools/usda/fetch.sh                                   # once: downloads and unzips into tools/usda/data/ (gitignored)
python3 -I tools/usda/usda.py search rice glutinous   # foods whose description has every word, kcal per 100 g
python3 -I tools/usda/usda.py show 168883             # kcal per 100 g and the household portions with gram weights
python3 -I tools/usda/check_bank.py src/main/resources/meal-bank.json   # prints a table, PROBLEM lines, then OK or FAIL
```

Always run Python with `-I` and treat the CSVs as data only. The first
`usda.py` call builds `data/usda-index.json` from the CSVs (a few seconds).

`check_bank.py` is the full schema check and its docstring defines the
ingredient fields. It exits 1 on FAIL, so a script can gate on it;
`python3 -I test_check_bank.py` tests it. It also holds the per-serving kcal bands (breakfast
300-850, lunch and dinner 350-950, snack 80-450), which exist to catch
amount typos, not to judge a dish. Run it after every bank edit, then run
`./gradlew cleanTest test`, which re-checks the arithmetic in Java.
