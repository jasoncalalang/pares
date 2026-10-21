import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mealpal_ph/data/sample_week.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:mealpal_ph/widgets/widgets.dart';

import '../helpers.dart';

/// What a screen reader is told about each control.
void main() {
  testWidgets('a choice says whether it is the selected one of its group',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(Row(children: [
      Expanded(child: MpChoiceButton(label: 'Male', selected: true, onTap: () {})),
      Expanded(child: MpChoiceButton(label: 'Female', selected: false, onTap: () {})),
    ])));
    expect(
      tester.getSemantics(find.text('Male')),
      isSemantics(
        label: 'Male',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Female')),
      isSemantics(label: 'Female', hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('a store tile says whether the store is picked, without its '
      'monogram', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(Row(children: [
      Expanded(
        child: MpStoreTile(name: 'Puregold', monogram: 'P', selected: true, onTap: () {}),
      ),
      Expanded(
        child: MpStoreTile(name: 'Savemore', monogram: 'S', selected: false, onTap: () {}),
      ),
    ])));
    expect(
      tester.getSemantics(find.text('Puregold')),
      isSemantics(
        label: 'Puregold',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Savemore')),
      isSemantics(label: 'Savemore', hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('the day strip reads each day once and marks the one shown',
      (tester) async {
    final handle = tester.ensureSemantics();
    await phone(tester);
    await tester.pumpWidget(host(Padding(
      padding: const EdgeInsets.all(22),
      child: MpDayStrip(
        days: Weekday.values,
        dayNumbers: const [20, 21, 22, 23, 24, 25, 26],
        selected: 3,
        onSelect: (_) {},
      ),
    )));
    expect(
      tester.getSemantics(find.text('THU')),
      isSemantics(
        label: 'Thursday 23',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('MON')),
      isSemantics(label: 'Monday 20', hasSelectedState: true, isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('a big value field is named by its label and spoken unit',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(MpBigValueField(
      label: 'Weight',
      value: 74,
      unit: 'kg',
      spokenUnit: 'kilograms',
      onChanged: (_) {},
    )));
    final field = tester.getSemantics(find.byType(EditableText));
    expect(field.label, 'Weight, in kilograms');
    expect(field.value, '74');
    handle.dispose();
  });

  testWidgets('a grocery row reads its name once and its checked state',
      (tester) async {
    final handle = tester.ensureSemantics();
    final section = sampleGroceryList(budgetPhp: 2500).sections[1];
    await tester.pumpWidget(host(SingleChildScrollView(
      child: MpGrocerySection(
        section: section,
        expanded: true,
        onToggle: () {},
        checked: const {0},
        onCheck: (_) {},
      ),
    )));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Rice')),
      isSemantics(
        label: 'Rice\n5 kg\n₱285',
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('a store section header says whether it is expanded',
      (tester) async {
    final handle = tester.ensureSemantics();
    final section = sampleGroceryList(budgetPhp: 2500).sections[1];
    var expanded = true;
    await tester.pumpWidget(host(StatefulBuilder(
      builder: (context, set) => SingleChildScrollView(
        child: MpGrocerySection(
          section: section,
          expanded: expanded,
          onToggle: () => set(() => expanded = !expanded),
          checked: const {},
          onCheck: (_) {},
        ),
      ),
    )));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Puregold')),
      isSemantics(
        label: 'Puregold\n6 items\n₱530',
        isButton: true,
        hasExpandedState: true,
        isExpanded: true,
      ),
    );
    await tester.tap(find.text('Puregold'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Puregold')),
      isSemantics(hasExpandedState: true, isExpanded: false),
    );
    handle.dispose();
  });

  testWidgets('each swap button names its slot, and the dish is a live region',
      (tester) async {
    final handle = tester.ensureSemantics();
    await phone(tester);
    final monday = sampleWeek().first;
    await tester.pumpWidget(host(Column(children: [
      for (final meal in monday.meals) MpMealCard(meal: meal, onSwap: () {}),
    ])));
    for (final slot in ['breakfast', 'lunch', 'dinner', 'snack']) {
      expect(find.bySemanticsLabel('Swap $slot'), findsOneWidget, reason: slot);
    }
    expect(
      tester.getSemantics(find.text('Tapsilog: beef tapa, garlic rice and egg')),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });
}
