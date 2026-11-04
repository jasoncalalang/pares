import '../mealpal_ph.dart';
import 'store_tiles.dart';

/// The picked stores as the grocery list needs them, in the order Where you
/// shop lists them (chains, then local). Ids the catalog does not know are
/// skipped.
List<ShoppingStop> shoppingStopsFor(Set<String> selectedIds) => [
  for (final t in [...chainTiles, ...localTiles])
    if (selectedIds.contains(t.id) && storeById(t.id) != null)
      ShoppingStop(
        id: t.id,
        name: t.name,
        monogram: t.monogram,
        type: storeById(t.id)!.type,
      ),
];
