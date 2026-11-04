import 'package:mealpal_ph/data/shopping_stops.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

void main() {
  test('stops follow the order Where you shop lists them, not the pick order', () {
    final stops = shoppingStopsFor({'palengke', 'puregold', 'sm-supermarket'});
    expect(stops.map((s) => s.id), ['sm-supermarket', 'puregold', 'palengke']);
  });

  test('a stop carries the tile name and monogram and the catalog type', () {
    final stops = shoppingStopsFor({'palengke', 's-and-r', 'grabmart', 'sari-sari'});
    final byId = {for (final s in stops) s.id: s};
    expect(byId['palengke']!.name, 'Wet market');
    expect(byId['palengke']!.monogram, 'W');
    expect(byId['palengke']!.type, StoreType.wetMarket);
    expect(byId['s-and-r']!.type, StoreType.warehouseClub);
    expect(byId['grabmart']!.type, StoreType.online);
    expect(byId['sari-sari']!.type, StoreType.sariSari);
  });

  test('nothing picked gives no stops, and unknown ids are skipped', () {
    expect(shoppingStopsFor({}), isEmpty);
    expect(shoppingStopsFor({'nope'}), isEmpty);
  });
}
