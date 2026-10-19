import 'package:mealpal_ph/mealpal_ph.dart';
import 'package:test/test.dart';

void main() {
  group('Philippine store catalog', () {
    test('has no North American chains (the thing we are replacing)', () {
      final names = phStores.map((s) => s.name.toLowerCase());
      for (final na in ['walmart', 'kroger', 'safeway', 'costco', 'target', 'aldi']) {
        expect(names.any((n) => n.contains(na)), isFalse, reason: 'found $na');
      }
    });

    test('includes the major PH supermarket chains', () {
      final ids = phStores.map((s) => s.id).toSet();
      for (final id in ['sm-supermarket', 'puregold', 'robinsons-supermarket', 'savemore', 'waltermart']) {
        expect(ids, contains(id));
      }
    });

    test('includes membership warehouse clubs', () {
      final clubs = storesByType(StoreType.warehouseClub).map((s) => s.id);
      expect(clubs, containsAll(['s-and-r', 'landers']));
    });

    test('represents the palengke and sari-sari reality NA apps ignore', () {
      final types = phStores.map((s) => s.type).toSet();
      expect(types, contains(StoreType.wetMarket));
      expect(types, contains(StoreType.sariSari));
    });

    test('every store has a unique id and a well-formed logo key', () {
      final ids = phStores.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
      final idPattern = RegExp(r'^[a-z0-9-]+$');
      final logoPattern = RegExp(r'^store-logos/[a-z0-9-]+\.(png|webp|svg)$');
      for (final s in phStores) {
        expect(idPattern.hasMatch(s.id), isTrue, reason: s.id);
        expect(logoPattern.hasMatch(s.logoKey), isTrue, reason: s.logoKey);
      }
    });

    test('prices everything in PHP', () {
      for (final s in phStores) {
        expect(s.currency, php);
      }
    });

    test('marks which stores support online ordering / delivery', () {
      final online = onlineStores().map((s) => s.id).toList();
      expect(online, contains('metromart'));
      expect(online, isNotEmpty);
      expect(online, isNot(contains('sari-sari')));
    });

    test('looks a store up by id and returns null for unknown ids', () {
      expect(storeById('puregold')?.name.toLowerCase(), contains('puregold'));
      expect(storeById('walmart'), isNull);
    });
  });
}
