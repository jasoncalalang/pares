import 'package:mealpal_ph/data/store_tiles.dart';
import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

void main() {
  test('every store tile points at a real catalog entry', () {
    for (final t in [...chainTiles, ...localTiles]) {
      expect(storeById(t.id), isNotNull, reason: t.id);
    }
  });

  test('local tiles are the palengke and the sari-sari', () {
    expect(localTiles.map((t) => t.id), ['palengke', 'sari-sari']);
    expect(localTiles.map((t) => t.name), ['Wet market', 'Corner store']);
  });

  test('chain tiles are the eight from the approved design, in order', () {
    expect(chainTiles.map((t) => t.name), [
      'SM Supermarket',
      'Puregold',
      'Savemore',
      'Robinsons',
      'S&R',
      'Landers',
      'WalterMart',
      'GrabMart',
    ]);
  });
}
