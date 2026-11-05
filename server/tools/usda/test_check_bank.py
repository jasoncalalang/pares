"""Tests for check_bank.py. Run: python3 -I test_check_bank.py
They need the USDA index (fetch.sh, then any usda.py call) and skip without it."""
import json, os, shutil, subprocess, sys, tempfile, unittest

HERE = os.path.dirname(os.path.abspath(__file__))
BANK = os.path.join(HERE, '..', '..', 'src', 'main', 'resources', 'meal-bank.json')
INDEX = os.path.join(HERE, 'data', 'usda-index.json')


def run_checker(bank):
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, 'bank.json')
        with open(path, 'w') as f:
            json.dump(bank, f)
        return subprocess.run([sys.executable, '-I', os.path.join(HERE, 'check_bank.py'), path],
                              capture_output=True, text=True)


@unittest.skipUnless(os.path.exists(INDEX), 'no USDA index')
class CheckBankTest(unittest.TestCase):
    def setUp(self):
        with open(BANK) as f:
            self.bank = json.load(f)

    def test_shipped_bank_passes_with_exit_zero(self):
        r = run_checker(self.bank)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertTrue(r.stdout.rstrip().endswith('OK'))

    def test_a_wrong_meal_kcal_fails_with_a_problem_line_and_a_nonzero_exit(self):
        next(m for m in self.bank['meals'] if m['id'] == 'tapsilog')['kcal'] = 1
        r = run_checker(self.bank)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('PROBLEM tapsilog: kcal 1', r.stdout)
        self.assertTrue(r.stdout.rstrip().endswith('FAIL'))

    def assert_problem_not_crash(self, bank, needle):
        r = run_checker(bank)
        self.assertNotIn('Traceback', r.stderr)
        self.assertNotEqual(r.returncode, 0)
        self.assertTrue(any(l.startswith('PROBLEM') and needle in l for l in r.stdout.splitlines()),
                        r.stdout)
        self.assertTrue(r.stdout.rstrip().endswith('FAIL'))

    def test_a_missing_gramsPerUnit_is_a_problem_not_a_crash(self):
        del self.bank['ingredients']['rice']['gramsPerUnit']
        self.assert_problem_not_crash(self.bank, 'rice: gramsPerUnit')

    def test_a_missing_kcalPer100g_is_a_problem_not_a_crash(self):
        del self.bank['ingredients']['rice']['kcalPer100g']
        self.assert_problem_not_crash(self.bank, 'rice: kcalPer100g')

    def test_a_null_edible_fraction_is_a_problem_not_a_crash(self):
        ing = next(i for i in self.bank['ingredients'].values() if i.get('edible'))
        ing['edible']['fraction'] = None
        self.assert_problem_not_crash(self.bank, 'edible')

    def test_a_non_numeric_portion_grams_is_a_problem_not_a_crash(self):
        ing = next(i for i in self.bank['ingredients'].values() if i['unit'] == 'pc')
        ing['portion']['grams'] = 'lots'
        self.assert_problem_not_crash(self.bank, 'portion.grams')


ZIPS = ['FoodData_Central_sr_legacy_food_csv_2018-04.zip', 'FoodData_Central_foundation_food_csv_2025-04-24.zip']


@unittest.skipUnless(all(os.path.exists(os.path.join(HERE, 'data', z)) for z in ZIPS), 'no downloaded zips')
class FetchTest(unittest.TestCase):
    def test_check_bank_works_right_after_fetch_sh_with_no_other_step(self):
        with tempfile.TemporaryDirectory() as d:
            for name in ('fetch.sh', 'usda.py', 'check_bank.py'):
                shutil.copy(os.path.join(HERE, name), d)
            os.mkdir(os.path.join(d, 'data'))
            for z in ZIPS:  # already present, so fetch.sh does not download
                os.symlink(os.path.join(HERE, 'data', z), os.path.join(d, 'data', z))
            subprocess.run(['bash', os.path.join(d, 'fetch.sh')], check=True, capture_output=True)
            r = subprocess.run([sys.executable, '-I', os.path.join(d, 'check_bank.py'), BANK],
                               capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr)


if __name__ == '__main__':
    unittest.main()
